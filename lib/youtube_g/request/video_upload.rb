class YouTubeG

  module Upload
    class UploadError < Exception; end
    class AuthenticationError < Exception; end

    # require 'youtube_g'
    #
    # uploader = YouTubeG::Upload::VideoUpload.new("user", "pass", "dev-key")
    # uploader.upload File.open("test.m4v"), :title => 'test',
    #                                        :description => 'cool vid d00d',
    #                                        :category => 'People',
    #                                        :keywords => %w[cool blah test]

    class VideoUpload

      def initialize user, pass, dev_key, client_id = 'youtube_g'
        @user, @pass, @dev_key, @client_id = user, pass, dev_key, client_id
      end

      #
      # Upload "data" to youtube, where data is either an IO object or
      # raw file data.
      # The hash keys for opts (which specify video info) are as follows:
      #   :mime_type
      #   :filename
      #   :title
      #   :description
      #   :category
      #   :keywords
      #   :private
      # Specifying :private will make the video private, otherwise it will be public.
      #
      # When one of the fields is invalid according to YouTube,
      # an UploadError will be returned. Its message contains a list of newline separated
      # errors, containing the key and its error code.
      # 
      # When the authentication credentials are incorrect, an AuthenticationError will be raised.
      def upload data, opts = {}
        # If data can be read, use the first 1024 bytes as filename. If data
        # is a file, use path. If data is a string, checksum it
        opst[:filename] ||= if data.respond_to?(:path)
          Digest::MD5.hexdigest(data.path)
        elsif data.respond_to?(:read)
          chunk = data.read(1024)
          data.rewind
          Digest::MD5.hexdigest(chunk)
        else
          Digest::MD5.hexdigest(data)
        end
          
        @opts = { :mime_type => 'video/mp4',
                  :title => '',
                  :description => '',
                  :category => '',
                  :keywords => [] }.merge(opts)

        post_body_io = generate_upload_body(boundary, video_xml, data)

        upload_headers = {
          "Authorization"  => "GoogleLogin auth=#{auth_token}",
          "X-GData-Client" => "#{@client_id}",
          "X-GData-Key"    => "key=#{@dev_key}",
          "Slug"           => "#{@opts[:filename]}",
          "Content-Type"   => "multipart/related; boundary=#{boundary}",
          "Content-Length" => "#{post_body_io.expected_length}",
          "Transfer-Encoding" => "chunked" # We will stream instead of posting at once
        }

        Net::HTTP.start(base_url) do | session |
          # Use the more convoluted request creation to use the IO as post body. Due to the
          # fact that Net::HTTP has been written by alies from Jupiter there is no other way to do it,
          # at least currently
          path = '/feeds/api/users/%s/uploads' % @user
          post = HTTP::Post.new(nil, nil, path, upload_headers)
          post.body_stream = post_body_io
          
          response = session.request(post)
          
          if response.code.to_i == 403
            raise AuthenticationError, response.body[/<TITLE>(.+)<\/TITLE>/, 1]
          elsif response.code.to_i != 201
            upload_error = ''
            xml = REXML::Document.new(response.body)
            errors = xml.elements["//errors"]
            errors.each do |error|
              location = error.elements["location"].text[/media:group\/media:(.*)\/text\(\)/,1]
              code = error.elements["code"].text
              upload_error << sprintf("%s: %s\r\n", location, code)
            end
            raise UploadError, upload_error
          end
          xml = REXML::Document.new(response.body)
          return xml.elements["//id"].text[/videos\/(.+)/, 1]
        end

      end

      private

      def base_url #:nodoc:
        "uploads.gdata.youtube.com"
      end

      def boundary #:nodoc:
        "An43094fu"
      end

      def auth_token #:nodoc:
        unless @auth_token
          http = Net::HTTP.new("www.google.com", 443)
          http.use_ssl = true
          body = "Email=#{CGI::escape @user}&Passwd=#{CGI::escape @pass}&service=youtube&source=#{CGI::escape @client_id}"
          response = http.post("/youtube/accounts/ClientLogin", body, "Content-Type" => "application/x-www-form-urlencoded")
          raise UploadError, response.body[/Error=(.+)/,1] if response.code.to_i != 200
          @auth_token = response.body[/Auth=(.+)/, 1]

        end
        @auth_token
      end
      
      def video_xml #:nodoc:
        b = Builder::XML.new
        b.instruct!
        b.entry(:xmlns => "http://www.w3.org/2005/Atom", 'xmlns:media' => "http://search.yahoo.com/mrss/", 'xmlns:yt' => "http://gdata.youtube.com/schemas/2007") do | m |
          m.tag!("media:group") do | mg |
            mg.tag!("media:title", :type => "plain") { @opts[:title] }
            mg.tag!("media:description", :type => "plain") { @opts[:description] }
            mg.tag!("media:keywords") { @opts[:keywords].join(",") }
            mg.tag!('media:category', :scheme => "http://gdata.youtube.com/schemas/2007/categories.cat") { @opts[:category] }
            mg.tag!('yt:private') if @opts[:private]
          end
        end.to_s
      end

      def generate_upload_body(boundary, video_xml, data) #:nodoc:
        post_body = []
        post_body << "--#{boundary}\r\n"
        post_body << "Content-Type: application/atom+xml; charset=UTF-8\r\n\r\n"
        post_body << video_xml
        post_body << "\r\n--#{boundary}\r\n"
        post_body << "Content-Type: #{@opts[:mime_type]}\r\nContent-Transfer-Encoding: binary\r\n\r\n"
        post_body << data
        post_body << "\r\n--#{boundary}--\r\n"
        
        YouTubeG::TapeIO.new(post_body)
      end

    end
  end
end