class YouTubeIt

  module Upload
    class UploadError < YouTubeIt::Error; end
    class AuthenticationError < YouTubeIt::Error; end

    # Implements video uploads/updates/deletions
    #
    #   require 'youtube_it'
    #
    #   uploader = YouTubeIt::Upload::VideoUpload.new("user", "pass", "dev-key")
    #   uploader.upload File.open("test.m4v"), :title => 'test',
    #                                        :description => 'cool vid d00d',
    #                                        :category => 'People',
    #                                        :keywords => %w[cool blah test]
    #
    class VideoUpload
      include YouTubeIt::Logging
      def initialize user, pass, dev_key, access_token = nil, authsub_token = nil, client_id = 'youtube_it'
        @user, @password, @dev_key, @access_token, @authsub_token, @client_id  = user, pass, dev_key, access_token, authsub_token, client_id
        @http_debugging = false
      end

      def initialize *params
        if params.first.is_a?(Hash)
          hash_options = params.first
          @user                          = hash_options[:username]
          @password                      = hash_options[:password]
          @dev_key                       = hash_options[:dev_key]
          @access_token                  = hash_options[:access_token]
          @authsub_token                 = hash_options[:authsub_token]
          @client_id                     = hash_options[:client_id] || "youtube_it"
        else
          puts "* warning: the method YouTubeIt::Upload::VideoUpload.new(username, password, dev_key) is depricated, use YouTubeIt::Upload::VideoUpload.new(:username => 'user', :password => 'passwd', :dev_key => 'dev_key')"
          @user                          = params.shift
          @password                      = params.shift
          @dev_key                       = params.shift
          @access_token                  = params.shift
          @authsub_token                 = params.shift
          @client_id                     = params.shift || "youtube_it"
        end
      end


      def enable_http_debugging
        @http_debugging = true
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
      # New V2 api hash keys for accessControl:
      #   :rate
      #   :comment
      #   :commentVote
      #   :videoRespond
      #   :list
      #   :embed
      #   :syndicate
      # Specifying :private will make the video private, otherwise it will be public.
      #
      # When one of the fields is invalid according to YouTube,
      # an UploadError will be raised. Its message contains a list of newline separated
      # errors, containing the key and its error code.
      #
      # When the authentication credentials are incorrect, an AuthenticationError will be raised.
      def upload(data, opts = {})
        response = nil
        @opts    = { :mime_type => 'video/mp4',
                     :title => '',
                     :description => '',
                     :category => '',
                     :keywords => [] }.merge(opts)

        @opts[:filename] ||= generate_uniq_filename_from(data)

        post_body_io = generate_upload_io(video_xml, data)

        upload_header = {
            "Slug"           => "#{@opts[:filename]}",
            "Content-Type"   => "multipart/related; boundary=#{boundary}",
            "Content-Length" => "#{post_body_io.expected_length}",
        }

        if @access_token.nil?
          upload_header.merge!(authorization_headers).delete("GData-Version")
          http = Net::HTTP.new(uploads_url)
          http.set_debug_output(logger) if @http_debugging
          path = '/feeds/api/users/default/uploads'
          http.start do | session |
            post = Net::HTTP::Post.new(path, upload_header)
            post.body_stream = post_body_io
            response = session.request(post)
          end
        else
          upload_header.merge!(authorization_headers_for_oauth).delete("GData-Version")
          url = 'http://%s/feeds/api/users/default/uploads' % uploads_url
          response = @access_token.post(url, post_body_io, upload_header)
        end
        raise_on_faulty_response(response)
        return YouTubeIt::Parser::VideoFeedParser.new(response.body).parse
      end

      # Updates a video in YouTube.  Requires:
      #   :title
      #   :description
      #   :category
      #   :keywords
      # The following are optional attributes:
      #   :private
      # When the authentication credentials are incorrect, an AuthenticationError will be raised.
      def update(video_id, options)
        response = nil
        @opts = options
        update_body = video_xml
        update_header = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{update_body.length}",
        }
        update_url = "/feeds/api/users/default/uploads/%s" % video_id

        if @access_token.nil?
          update_header.merge!(authorization_headers)
          http_connection do |session|
            response = session.put(update_url, update_body, update_header)
          end
        else
          update_header.merge!(authorization_headers_for_oauth)
          response = @access_token.put("http://%s%s" % [base_url,update_url], update_body, update_header)
        end

        raise_on_faulty_response(response)
        return YouTubeIt::Parser::VideoFeedParser.new(response.body).parse
      end

      # Delete a video on YouTube
      def delete(video_id)
        response      = nil
        delete_header = {
          "Content-Type"   => "application/atom+xml; charset=UTF-8",
          "Content-Length" => "0",
        }
        delete_url = "/feeds/api/users/default/uploads/%s" % video_id

        if @access_token.nil?
          delete_header.merge!(authorization_headers)
          http_connection do |session|
            response = session.delete(delete_url, delete_header)
          end
        else
          delete_header.merge!(authorization_headers_for_oauth)
          response = @access_token.delete("http://%s%s" % [base_url,delete_url], delete_header)
        end
        raise_on_faulty_response(response)
        return true
      end

      def get_upload_token(options, nexturl)
        response      = nil
        @opts         = options
        token_body    = video_xml
        token_header  = {
          "Content-Type"   => "application/atom+xml; charset=UTF-8",
          "Content-Length" => "#{token_body.length}",
        }
        token_url = "/action/GetUploadToken"
        
        if @access_token.nil?
          token_header.merge!(authorization_headers)
          http_connection do |session|
            response = session.post(token_url, token_body, token_header)
          end
        else
          token_header.merge!(authorization_headers_for_oauth)
          response = @access_token.post("http://%s%s" % [base_url, token_url], token_body, token_header)
        end
        raise_on_faulty_response(response)
        return {:url    => "#{response.body[/<url>(.+)<\/url>/, 1]}?nexturl=#{nexturl}",
                :token  => response.body[/<token>(.+)<\/token>/, 1]}
      end

      def add_comment(video_id, comment)
        response        = nil
        comment_body    = video_xml_for(:comment => comment)
        comment_header  = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{comment_body.length}",
        }
        comment_url = "/feeds/api/videos/%s/comments" % video_id

        if @access_token.nil?
          comment_header.merge!(authorization_headers)
          http_connection do |session|
            response = session.post(comment_url, comment_body, comment_header)
          end
        else
          comment_header.merge!(authorization_headers_for_oauth)
          response = @access_token.post("http://%s%s" % [base_url, comment_url], comment_body, comment_header)
        end
        raise_on_faulty_response(response)
        {:code => response.code, :body => response.body}
      end

      def comments(video_id, opts = {})
        comment_url = "/feeds/api/videos/%s/comments?" % video_id
        comment_url << opts.collect { |k,p| [k,p].join '=' }.join('&')
        http_connection do |session|
          response = session.get(comment_url)
          raise_on_faulty_response(response)
          {:code => response.code, :body => response.body}
          return YouTubeIt::Parser::CommentsFeedParser.new(response).parse
        end
      end

      def add_favorite(video_id)
        response        = nil
        favorite_body   = video_xml_for(:favorite => video_id)
        favorite_header = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{favorite_body.length}",
        }
        favorite_url = "/feeds/api/users/default/favorites"
        
        if @access_token.nil?
          favorite_header.merge!(authorization_headers)
          http_connection do |session|
            response = session.post(favorite_url, favorite_body, favorite_header)
          end
        else
          favorite_header.merge!(authorization_headers_for_oauth)
          response = @access_token.post("http://%s%s" % [base_url, favorite_url], favorite_body, favorite_header)
        end
        raise_on_faulty_response(response)
        {:code => response.code, :body => response.body}
      end

      def delete_favorite(video_id)
        response        = nil
        favorite_header = {
          "Content-Type"   => "application/atom+xml; charset=UTF-8",
          "Content-Length" => "0",
        }
        favorite_url    = "/feeds/api/users/default/favorites/%s" % video_id
        
        if @access_token.nil?
          favorite_header.merge!(authorization_headers).delete("GData-Version")
          http_connection do |session|
            response = session.delete(favorite_url, favorite_header)
          end
        else
          favorite_header.merge!(authorization_headers_for_oauth).delete("GData-Version")
          response = @access_token.delete("http://%s%s" % [base_url, favorite_url], favorite_header)
        end
        raise_on_faulty_response(response)
        return true
      end

      def profile(user_id)
        profile_url = "/feeds/api/users/%s?v=2" % user_id
        http_connection do |session|
          response = session.get(profile_url)
          raise_on_faulty_response(response)
          return YouTubeIt::Parser::ProfileFeedParser.new(response).parse
        end
      end

      def playlist(playlist_id)
        playlist_url = "/feeds/api/playlists/%s?v=2" % playlist_id
        http_connection do |session|
          response = session.get(playlist_url)
          raise_on_faulty_response(response)
          return YouTubeIt::Parser::PlaylistFeedParser.new(response).parse
        end
      end

      def playlists
        playlist_url = "/feeds/api/users/default/playlists?v=2"
        http_connection do |session|
          response = session.get(playlist_url)
          raise_on_faulty_response(response)
          return response.body
        end
      end
      
      def playlists_for(user)
        playlist_url = "/feeds/api/users/#{user}/playlists?v=2"
        http_connection do |session|
          response = session.get(playlist_url)
          raise_on_faulty_response(response)
          return YouTubeIt::Parser::PlaylistsFeedParser.new(response).parse #return response.body
        end
      end

      def add_playlist(options)
        response        = nil
        playlist_body   = video_xml_for_playlist(options)
        playlist_header = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{playlist_body.length}",
        }
        playlist_url = "/feeds/api/users/default/playlists"

        if @access_token.nil?
          playlist_header.merge!(authorization_headers)
          http_connection do |session|
            response = session.post(playlist_url, playlist_body, playlist_header)
          end
        else
          playlist_header.merge!(authorization_headers_for_oauth)
          response = @access_token.post("http://%s%s" % [base_url, playlist_url], playlist_body, playlist_header)
        end
        raise_on_faulty_response(response)
        return YouTubeIt::Parser::PlaylistFeedParser.new(response).parse
      end

      def add_video_to_playlist(playlist_id, video_id)
        response        = nil
        playlist_body   = video_xml_for(:playlist => video_id)
        playlist_header = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{playlist_body.length}",
        }
        playlist_url = "/feeds/api/playlists/%s" % playlist_id

        if @access_token.nil?
          playlist_header.merge!(authorization_headers)
          http_connection do |session|
            response = session.post(playlist_url, playlist_body, playlist_header)
          end
        else
          playlist_header.merge!(authorization_headers_for_oauth)
          response = @access_token.post("http://%s%s" % [base_url, playlist_url], playlist_body, playlist_header)
        end
        raise_on_faulty_response(response)
        {:code => response.code, :body => response.body, :playlist_entry_id => playlist_entry_id_from_playlist(response.body)}
      end

      def update_playlist(playlist_id, options)
        response        = nil
        playlist_body   = video_xml_for_playlist(options)
        playlist_header = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{playlist_body.length}",
        }
        playlist_url = "/feeds/api/users/default/playlists/%s" % playlist_id

        if @access_token.nil?
          playlist_header.merge!(authorization_headers)
          http_connection do |session|
            response = session.put(playlist_url, playlist_body, playlist_header)
          end
        else
          playlist_header.merge!(authorization_headers_for_oauth)
          response = @access_token.put("http://%s%s" % [base_url, playlist_url], playlist_body, playlist_header)
        end
        raise_on_faulty_response(response)
        return YouTubeIt::Parser::PlaylistFeedParser.new(response).parse
      end

      def delete_video_from_playlist(playlist_id, playlist_entry_id)
        response        = nil
        playlist_header = {
          "Content-Type"   => "application/atom+xml",
        }
        playlist_url = "/feeds/api/playlists/%s/%s" % [playlist_id, playlist_entry_id]

        if @access_token.nil?
          playlist_header.merge!(authorization_headers)
          http_connection do |session|
            response = session.delete(playlist_url, playlist_header)
          end
        else
          playlist_header.merge!(authorization_headers_for_oauth)
          response = @access_token.delete("http://%s%s" % [base_url, playlist_url], playlist_header)
        end
        raise_on_faulty_response(response)
        return true
      end

      def delete_playlist(playlist_id)
        response        = nil
        playlist_header = {
          "Content-Type"   => "application/atom+xml; charset=UTF-8",
        }
        playlist_url = "/feeds/api/users/default/playlists/%s" % playlist_id

        if @access_token.nil?
          playlist_header.merge!(authorization_headers)
          http_connection do |session|
            response = session.delete(playlist_url, playlist_header)
          end
        else
          playlist_header.merge!(authorization_headers_for_oauth)
          response = @access_token.delete("http://%s%s" % [base_url, playlist_url], playlist_header)
        end
        raise_on_faulty_response(response)
        return true
      end

      def favorites
        favorite_url = "/feeds/api/users/default/favorites"
        http_connection do |session|
          response = session.get(favorite_url)
          raise_on_faulty_response(response)
          return response.body
        end
      end

      def get_current_user
        current_user_url = "/feeds/api/users/default"
        response = ''
        if @access_token.nil?
          http_connection do |session|
            response = session.get2(current_user_url, authorization_headers)
          end
        else
          response = @access_token.get("http://gdata.youtube.com/feeds/api/users/default")
        end

        raise_on_faulty_response(response)
        REXML::Document.new(response.body).elements["entry"].elements['author'].elements['name'].text
      end

      private

      def uploads_url
        ["uploads", base_url].join('.')
      end

      def base_url
        "gdata.youtube.com"
      end

      def boundary
        "An43094fu"
      end

      def authorization_headers_for_oauth
        {
          "X-GData-Client" => "#{@client_id}",
          "X-GData-Key"    => "key=#{@dev_key}",
          "GData-Version"  => "2",
        }
      end

      def authorization_headers
        header = {
                  "X-GData-Client" => "#{@client_id}",
                  "X-GData-Key"    => "key=#{@dev_key}",
                  "GData-Version" => "2",
                }
        if @authsub_token
          header.merge!("Authorization"  => "AuthSub token=#{@authsub_token}")
        else
          header.merge!("Authorization"  => "GoogleLogin auth=#{auth_token}")
        end
        header
      end

      def parse_upload_error_from(string)
        begin
          REXML::Document.new(string).elements["//errors"].inject('') do | all_faults, error|
            if error.elements["internalReason"]
              msg_error = error.elements["internalReason"].text
            elsif error.elements["location"]
              msg_error = error.elements["location"].text[/media:group\/media:(.*)\/text\(\)/,1]
            else
              msg_error = "Unspecified error"
            end
            code = error.elements["code"].text if error.elements["code"]
            all_faults + sprintf("%s: %s\n", msg_error, code)
          end
        rescue
          string[/<TITLE>(.+)<\/TITLE>/, 1] || string 
        end
      end

      def raise_on_faulty_response(response)
        response_code = response.code.to_i
        msg = parse_upload_error_from(response.body.gsub(/\n/, ''))

        if response_code == 403 || response_code == 401
        #if response_code / 10 == 40
          raise AuthenticationError, msg
        elsif response_code / 10 != 20 # Response in 20x means success
          raise UploadError, msg
        end
      end

      def uploaded_video_id_from(string)
        xml = REXML::Document.new(string)
        xml.elements["//id"].text[/videos\/(.+)/, 1]
      end

      def playlist_id_from(string)
        xml = REXML::Document.new(string)
        entry = xml.elements["entry"]
        entry.elements["id"].text[/playlist([^<]+)/, 1].sub(':','')
      end

      # If data can be read, use the first 1024 bytes as filename. If data
      # is a file, use path. If data is a string, checksum it
      def generate_uniq_filename_from(data)
        if data.respond_to?(:path)
          Digest::MD5.hexdigest(data.path)
        elsif data.respond_to?(:read)
          chunk = data.read(1024)
          data.rewind
          Digest::MD5.hexdigest(chunk)
        else
          Digest::MD5.hexdigest(data)
        end
      end

      def auth_token
        @auth_token ||= begin
          http = Net::HTTP.new("www.google.com", 443)
          http.use_ssl = true
          body = "Email=#{YouTubeIt.esc @user}&Passwd=#{YouTubeIt.esc @password}&service=youtube&source=#{YouTubeIt.esc @client_id}"
          response = http.post("/youtube/accounts/ClientLogin", body, "Content-Type" => "application/x-www-form-urlencoded")
          raise UploadError, response.body[/Error=(.+)/,1] if response.code.to_i != 200
          @auth_token = response.body[/Auth=(.+)/, 1]
        end
      end

      # TODO: isn't there a cleaner way to output top-notch XML without requiring stuff all over the place?
      def video_xml
        b = Builder::XmlMarkup.new
        b.instruct!
        b.entry(:xmlns => "http://www.w3.org/2005/Atom", 'xmlns:media' => "http://search.yahoo.com/mrss/", 'xmlns:yt' => "http://gdata.youtube.com/schemas/2007") do | m |
          m.tag!("media:group") do | mg |
            mg.tag!("media:title", @opts[:title], :type => "plain")
            mg.tag!("media:description", @opts[:description], :type => "plain")
            mg.tag!("media:keywords", @opts[:keywords].join(","))
            mg.tag!('media:category', @opts[:category], :scheme => "http://gdata.youtube.com/schemas/2007/categories.cat")
            mg.tag!('yt:private') if @opts[:private]
            mg.tag!('media:category', @opts[:dev_tag], :scheme => "http://gdata.youtube.com/schemas/2007/developertags.cat") if @opts[:dev_tag]
          end
          m.tag!("yt:accessControl", :action => "rate", :permission => @opts[:rate]) if @opts[:rate]
          m.tag!("yt:accessControl", :action => "comment", :permission => @opts[:comment]) if @opts[:comment]
          m.tag!("yt:accessControl", :action => "commentVote", :permission => @opts[:commentVote]) if @opts[:commentVote]
          m.tag!("yt:accessControl", :action => "videoRespond", :permission => @opts[:videoRespond]) if @opts[:videoRespond]
          m.tag!("yt:accessControl", :action => "list", :permission => @opts[:list]) if @opts[:list]
          m.tag!("yt:accessControl", :action => "embed", :permission => @opts[:embed]) if @opts[:embed]
          m.tag!("yt:accessControl", :action => "syndicate", :permission => @opts[:syndicate]) if @opts[:syndicate]
        end.to_s
      end

      def video_xml_for(data)
        b = Builder::XmlMarkup.new
        b.instruct!
        b.entry(:xmlns => "http://www.w3.org/2005/Atom", 'xmlns:yt' => "http://gdata.youtube.com/schemas/2007") do | m |
          m.content(data[:comment]) if data[:comment]
          m.id(data[:favorite] || data[:playlist]) if data[:favorite] || data[:playlist]
        end.to_s
      end

      def video_xml_for_playlist(data)
        b = Builder::XmlMarkup.new
        b.instruct!
        b.entry(:xmlns => "http://www.w3.org/2005/Atom", 'xmlns:yt' => "http://gdata.youtube.com/schemas/2007") do | m |
          m.title(data[:title]) if data[:title]
          m.summary(data[:description] || data[:summary]) if data[:description] || data[:summary]
          m.tag!('yt:private') if data[:private]
        end.to_s
      end

      def generate_upload_io(video_xml, data)
        post_body = [
          "--#{boundary}\r\n",
          "Content-Type: application/atom+xml; charset=UTF-8\r\n\r\n",
          video_xml,
          "\r\n--#{boundary}\r\n",
          "Content-Type: #{@opts[:mime_type]}\r\nContent-Transfer-Encoding: binary\r\n\r\n",
          data,
          "\r\n--#{boundary}--\r\n",
        ]

        # Use Greedy IO to not be limited by 1K chunks
        YouTubeIt::GreedyChainIO.new(post_body)
      end

      def playlist_entry_id_from_playlist(string)
        playlist_xml = REXML::Document.new(string)
        playlist_xml.elements.each("/entry") do |item|
          return item.elements["id"].text[/^.*:([^:]+)$/,1]
        end
      end

      def http_connection
        http = Net::HTTP.new(base_url)
        http.set_debug_output(logger) if @http_debugging
        http.start do |session|
          yield(session)
        end
      end
    end
  end
end
