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
        data = data.respond_to?(:read) ? data.read : data
        @opts = { :mime_type => 'video/mp4',
                  :filename => Digest::MD5.hexdigest(data),
                  :title => '',
                  :description => '',
                  :category => '',
                  :keywords => [] }.merge(opts)

        uploadBody = generate_upload_body(boundary, video_xml, data)

        uploadHeader = {
          "Authorization"  => "GoogleLogin auth=#{auth_token}",
          "X-GData-Client" => "#{@client_id}",
          "X-GData-Key"    => "key=#{@dev_key}",
          "Slug"           => "#{@opts[:filename]}",
          "Content-Type"   => "multipart/related; boundary=#{boundary}",
          "Content-Length" => "#{uploadBody.length}"
        }

        Net::HTTP.start(base_url) do |upload|
          response = upload.post('/feeds/api/users/' << @user << '/uploads', uploadBody, uploadHeader)
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
        video_xml = ''
        video_xml << '<?xml version="1.0"?>'
        video_xml << '<entry xmlns="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/" xmlns:yt="http://gdata.youtube.com/schemas/2007">'
        video_xml << '<media:group>'
        video_xml << '<media:title type="plain">%s</media:title>'               % @opts[:title]
        video_xml << '<media:description type="plain">%s</media:description>'   % @opts[:description]
        video_xml << '<media:keywords>%s</media:keywords>'                      % @opts[:keywords].join(",")
        video_xml << '<media:category scheme="http://gdata.youtube.com/schemas/2007/categories.cat">%s</media:category>' % @opts[:category]
        video_xml << '<yt:private/>' if @opts[:private]
        video_xml << '</media:group>'
        video_xml << '</entry>'
      end

      def generate_upload_body(boundary, video_xml, data) #:nodoc:
        uploadBody = ""
        uploadBody << "--#{boundary}\r\n"
        uploadBody << "Content-Type: application/atom+xml; charset=UTF-8\r\n\r\n"
        uploadBody << video_xml
        uploadBody << "\r\n--#{boundary}\r\n"
        uploadBody << "Content-Type: #{@opts[:mime_type]}\r\nContent-Transfer-Encoding: binary\r\n\r\n"
        uploadBody << data
        uploadBody << "\r\n--#{boundary}--\r\n"
      end

    end
  end
end