class YouTubeIt
  module Upload
    class VideoUpload
      include YouTubeIt::Logging

      def initialize *params
        if params.first.is_a?(Hash)
          hash_options = params.first
          @user                          = hash_options[:username]
          @password                      = hash_options[:password]
          @dev_key                       = hash_options[:dev_key]
          @access_token                  = hash_options[:access_token]
          @authsub_token                 = hash_options[:authsub_token]
          @client_id                     = hash_options[:client_id] || "youtube_it"
          @config_token                  = hash_options[:config_token]
        else
          puts "* warning: the method YouTubeIt::Upload::VideoUpload.new(username, password, dev_key) is depricated, use YouTubeIt::Upload::VideoUpload.new(:username => 'user', :password => 'passwd', :dev_key => 'dev_key')"
          @user                          = params.shift
          @password                      = params.shift
          @dev_key                       = params.shift
          @access_token                  = params.shift
          @authsub_token                 = params.shift
          @client_id                     = params.shift || "youtube_it"
          @config_token                  = params.shift
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

        upload_url = "/feeds/api/users/default/uploads"
        response = yt_session(uploads_url).post(upload_url, post_body_io, upload_header)

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
        @opts         = options
        update_body   = video_xml
        update_header = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{update_body.length}",
        }
        update_url = "/feeds/api/users/default/uploads/%s" % video_id
        response   = yt_session.put(update_url, update_body, update_header)
        
        return YouTubeIt::Parser::VideoFeedParser.new(response.body).parse
      end

      # Fetches the data of a video, which may be private. The video must be owned by this user.
      # When the authentication credentials are incorrect, an AuthenticationError will be raised.
      def get_my_video(video_id)
        get_header = {
                 "Content-Type"   => "application/atom+xml",
                 "Content-Length" => "0",
                 }
        get_url  = "/feeds/api/users/default/uploads/%s" % video_id
        response = yt_session.get(get_url, get_header)
        
        return YouTubeIt::Parser::VideoFeedParser.new(response.body).parse
      end

      # Fetches the data of the videos of the current user, which may be private. 
      # When the authentication credentials are incorrect, an AuthenticationError will be raised.
      def get_my_videos(opts)
        max_results = opts[:per_page] || 50
        start_index = ((opts[:page] || 1) -1) * max_results +1
        get_header  = {
                 "Content-Type"   => "application/atom+xml",
                 "Content-Length" => "0",
                 }
        get_url  = "/feeds/api/users/default/uploads?max-results=#{max_results}&start-index=#{start_index}"
        response = yt_session.get(get_url, get_header)

        return YouTubeIt::Parser::VideosFeedParser.new(response.body).parse
      end

      # Delete a video on YouTube
      def delete(video_id)
        delete_header = {
          "Content-Type"   => "application/atom+xml; charset=UTF-8",
          "Content-Length" => "0",
        }
        delete_url = "/feeds/api/users/default/uploads/%s" % video_id
        response = yt_session.delete(delete_url, delete_header)

        return true
      end

      def get_upload_token(options, nexturl)
        @opts         = options
        token_body    = video_xml
        token_header  = {
          "Content-Type"   => "application/atom+xml; charset=UTF-8",
          "Content-Length" => "#{token_body.length}",
        }
        token_url = "/action/GetUploadToken"
        response = yt_session.post(token_url, token_body, token_header)
        
        return {:url    => "#{response.body[/<url>(.+)<\/url>/, 1]}?nexturl=#{nexturl}",
                :token  => response.body[/<token>(.+)<\/token>/, 1]}
      end

      def add_comment(video_id, comment)
        comment_body    = video_xml_for(:comment => comment)
        comment_header  = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{comment_body.length}",
        }
        comment_url = "/feeds/api/videos/%s/comments" % video_id

        response = yt_session.post(comment_url, comment_body, comment_header)
        
        return {:code => response.status, :body => response.body}
      end

      def comments(video_id, opts = {})
        comment_url = "/feeds/api/videos/%s/comments?" % video_id
        comment_url << opts.collect { |k,p| [k,p].join '=' }.join('&')
        response = yt_session.get(comment_url)
        
        return YouTubeIt::Parser::CommentsFeedParser.new(response).parse
      end

      def add_favorite(video_id)
        favorite_body   = video_xml_for(:favorite => video_id)
        favorite_header = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{favorite_body.length}",
        }
        favorite_url = "/feeds/api/users/default/favorites"
        response     = yt_session.post(favorite_url, favorite_body, favorite_header)
        
        return {:code => response.status, :body => response.body}
      end

      def delete_favorite(video_id)
        favorite_header = {
          "Content-Type"   => "application/atom+xml; charset=UTF-8",
          "Content-Length" => "0",
        }
        favorite_url    = "/feeds/api/users/default/favorites/%s" % video_id
        response = yt_session.delete(favorite_url, favorite_header)
        
        return true
      end

      def profile(user)
        profile_url    = "/feeds/api/users/%s?v=2" % (user ? user : "default")
        profile_header = {
          "Content-Type"   => "application/atom+xml; charset=UTF-8"
        }
        response = yt_session.get(profile_url, profile_header)

        return YouTubeIt::Parser::ProfileFeedParser.new(response).parse
      end

      def playlist(playlist_id)
        playlist_url = "/feeds/api/playlists/%s?v=2" % playlist_id
        response     = yt_session.get(playlist_url)
        
        return YouTubeIt::Parser::PlaylistFeedParser.new(response).parse
      end

      def playlists(user)
        playlist_url = "/feeds/api/users/%s/playlists?v=2" % (user ? user : "default")
        response     = yt_session.get(playlist_url)
        
        return YouTubeIt::Parser::PlaylistsFeedParser.new(response).parse
      end
      
      def add_playlist(options)
        playlist_body   = video_xml_for_playlist(options)
        playlist_header = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{playlist_body.length}",
        }
        playlist_url = "/feeds/api/users/default/playlists"
        response = yt_session.post(playlist_url, playlist_body, playlist_header)
        
        return YouTubeIt::Parser::PlaylistFeedParser.new(response).parse
      end

      def add_video_to_playlist(playlist_id, video_id)
        playlist_body   = video_xml_for(:playlist => video_id)
        playlist_header = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{playlist_body.length}",
        }
        playlist_url = "/feeds/api/playlists/%s" % playlist_id
        response = yt_session.post(playlist_url, playlist_body, playlist_header)
        
        return {:code => response.status, :body => response.body, :playlist_entry_id => playlist_entry_id_from_playlist(response.body)}
      end

      def update_playlist(playlist_id, options)
        playlist_body   = video_xml_for_playlist(options)
        playlist_header = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{playlist_body.length}",
        }
        playlist_url = "/feeds/api/users/default/playlists/%s" % playlist_id
        response = yt_session.put(playlist_url, playlist_body, playlist_header)
        
        return YouTubeIt::Parser::PlaylistFeedParser.new(response).parse
      end

      def delete_video_from_playlist(playlist_id, playlist_entry_id)
        playlist_header = {
          "Content-Type"   => "application/atom+xml",
        }
        playlist_url = "/feeds/api/playlists/%s/%s" % [playlist_id, playlist_entry_id]
        response = yt_session.delete(playlist_url, playlist_header)
        
        return true
      end

      def delete_playlist(playlist_id)
        playlist_header  = {
          "Content-Type" => "application/atom+xml; charset=UTF-8",
        }
        playlist_url     = "/feeds/api/users/default/playlists/%s" % playlist_id
        response = yt_session.delete(playlist_url, playlist_header)
        
        return true
      end

      def rate_video(video_id, rating)
        rating_body   = video_xml_for(:rating => rating)
        rating_header = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{rating_body.length}",
        }
        rating_url = "/feeds/api/videos/#{video_id}/ratings"
        response = yt_session.post(rating_url, rating_body, rating_header)
        
        return {:code => response.status, :body => response.body}
      end
      
      def subscriptions(user)
        subscription_url    = "/feeds/api/users/%s/subscriptions?v=2" % (user ? user : "default")
        subscription_header = {
          "Content-Type"   => "application/atom+xml",
        }
        response = yt_session.get(subscription_url, subscription_header)
        
        return YouTubeIt::Parser::SubscriptionFeedParser.new(response).parse
      end
            
      def subscribe_channel(channel_name)
        subscribe_body   = video_xml_for(:subscribe => channel_name)
        subscribe_header = {
          "Content-Type"   => "application/atom+xml",
          "Content-Length" => "#{subscribe_body.length}",
        }
        subscribe_url = "/feeds/api/users/default/subscriptions"
        response = yt_session.post(subscribe_url, subscribe_body, subscribe_header)
         
        return {:code => response.status, :body => response.body}
      end
      
      def unsubscribe_channel(subscription_id)
        unsubscribe_header = {
          "Content-Type"   => "application/atom+xml"
        }
        unsubscribe_url = "/feeds/api/users/default/subscriptions/%s" % subscription_id
        response = yt_session.delete(unsubscribe_url, unsubscribe_header)
           
        return {:code => response.status, :body => response.body}
      end
      
      def favorites(user, opts = {})
        favorite_url = "/feeds/api/users/%s/favorites#{opts.empty? ? '' : '?#{opts.to_param}'}" % (user ? user : "default")
        response     = yt_session.get(favorite_url)
        return YouTubeIt::Parser::VideosFeedParser.new(response.body).parse
      end

      def get_current_user
        current_user_url = "/feeds/api/users/default"
        response         = yt_session.get(current_user_url, authorization_headers)

        return REXML::Document.new(response.body).elements["entry"].elements['author'].elements['name'].text
      end

      private

      def uploads_url
        ["http://uploads", base_url.sub("http://","")].join('.')
      end

      def base_url
        "http://gdata.youtube.com"
      end

      def boundary
        "An43094fu"
      end

      def authorization_headers
        header = {
                  "X-GData-Client" => "#{@client_id}",
                  "X-GData-Key"    => "key=#{@dev_key}",
                  "GData-Version" => "2",
                }
        if @authsub_token
          header.merge!("Authorization"  => "AuthSub token=#{@authsub_token}")
        elsif @access_token.nil? && @authsub_token.nil?
          header.merge!("Authorization"  => "GoogleLogin auth=#{auth_token}")
        end
        header
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
          http  = Faraday.new("https://www.google.com")
          body = "Email=#{YouTubeIt.esc @user}&Passwd=#{YouTubeIt.esc @password}&service=youtube&source=#{YouTubeIt.esc @client_id}"
          response = http.post("/youtube/accounts/ClientLogin", body, "Content-Type" => "application/x-www-form-urlencoded")
          raise ::AuthenticationError.new(response.body[/Error=(.+)/,1], response.status.to_i) if response.status.to_i != 200
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
          m.tag!("yt:rating", :value => data[:rating]) if data[:rating]
          if(data[:subscribe])
            m.category(:scheme => "http://gdata.youtube.com/schemas/2007/subscriptiontypes.cat", :term => "channel")
            m.tag!("yt:username", data[:subscribe])
          end
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

      def yt_session(url = nil)
        Faraday.new(:url => url ? url : base_url) do |builder|
          builder.use Faraday::Request::OAuth, @config_token if @config_token
          builder.use Faraday::Request::AuthHeader, authorization_headers
          builder.use Faraday::Response::YouTubeIt 
          builder.adapter Faraday.default_adapter          
        end
      end
    end
  end
end
