class YouTubeIt
  module Upload
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
          puts "* warning: the method YouTubeIt::Upload::VideoUpload.new(username, password, dev_key) is deprecated, use YouTubeIt::Upload::VideoUpload.new(:username => 'user', :password => 'passwd', :dev_key => 'dev_key')"
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

      def uri?(string)
        uri = URI.parse(string)
        %w( http https ).include?(uri.scheme)
      rescue URI::BadURIError
        false
      rescue URI::InvalidURIError
        false
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
      def upload(video_data, opts = {})

        if video_data.is_a?(String) && uri?(video_data)
          data = YouTubeIt::Upload::RemoteFile.new(video_data, opts)
        else
          data = video_data
        end

        @opts    = { :mime_type => 'video/mp4',
                     :title => '',
                     :description => '',
                     :category => 'People',
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

        return YouTubeIt::Parser::VideoFeedParser.new(response.body).parse rescue nil
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
        @opts = { :title => '',
                  :description => '',
                  :category => 'People',
                  :keywords => [] }.merge(options)

        update_body = video_xml
        update_url  = "/feeds/api/users/default/uploads/%s" % video_id
        response    = yt_session.put(update_url, update_body)

        return YouTubeIt::Parser::VideoFeedParser.new(response.body).parse rescue nil
      end

      # Partial updates to a video.
      def partial_update(video_id, options)
        update_body = partial_video_xml(options)
        update_url  = "/feeds/api/users/default/uploads/%s" % video_id
        update_header = { "Content-Type" => "application/xml" }
        response    = yt_session.patch(update_url, update_body, update_header)

        return YouTubeIt::Parser::VideoFeedParser.new(response.body).parse rescue nil
      end

      def captions_update(video_id, data, options)
        @opts = {
            :language => 'en-US',
            :slug => ''
        }.merge(options)

        upload_header = {
            "Slug" => "#{URI.escape(@opts[:slug])}",
            "Content-Language"=>@opts[:language],
            "Content-Type" => "application/vnd.youtube.timedtext; charset=UTF-8",
            "Content-Length" => "#{data.length}",
        }
        upload_url = "/feeds/api/videos/#{video_id}/captions"
        response = yt_session(base_url).post(upload_url, data, upload_header)
        return YouTubeIt::Parser::CaptionFeedParser.new(response.body).parse
      end

      # Fetches the currently authenticated user's contacts (i.e. friends).
      # When the authentication credentials are incorrect, an AuthenticationError will be raised.
      def get_my_contacts(opts)
        contacts_url = "/feeds/api/users/default/contacts?v=#{YouTubeIt::API_VERSION}"
        contacts_url << opts.collect { |k,p| [k,p].join '=' }.join('&')
        response = yt_session.get(contacts_url)

        return YouTubeIt::Parser::ContactsParser.new(response).parse
      end

      def send_message(opts)
        message_body = message_xml_for(opts)
        message_url  = "/feeds/api/users/%s/inbox" % opts[:recipient_id]
        response     = yt_session.post(message_url, message_body)

        return {:code => response.status, :body => response.body}
      end

      # Fetches the currently authenticated user's messages (i.e. inbox).
      # When the authentication credentials are incorrect, an AuthenticationError will be raised.
      def get_my_messages(opts)
        messages_url = "/feeds/api/users/default/inbox"
        messages_url << opts.collect { |k,p| [k,p].join '=' }.join('&')
        response = yt_session.get(messages_url)

        return YouTubeIt::Parser::MessagesParser.new(response).parse
      end

      # Fetches the data of a video, which may be private. The video must be owned by this user.
      # When the authentication credentials are incorrect, an AuthenticationError will be raised.
      def get_my_video(video_id)
        get_url  = "/feeds/api/users/default/uploads/%s" % video_id
        response = yt_session.get(get_url)

        return YouTubeIt::Parser::VideoFeedParser.new(response.body).parse rescue nil
      end

      # Fetches the data of the videos of the current user, which may be private.
      # When the authentication credentials are incorrect, an AuthenticationError will be raised.
      def get_my_videos(opts)
        max_results = opts[:per_page] || 50
        start_index = ((opts[:page] || 1) -1) * max_results +1
        get_url     = "/feeds/api/users/default/uploads?max-results=#{max_results}&start-index=#{start_index}"
        response    = yt_session.get(get_url)

        return YouTubeIt::Parser::VideosFeedParser.new(response.body).parse
      end

      # Delete a video on YouTube
      def delete(video_id)
        delete_url = "/feeds/api/users/default/uploads/%s" % video_id
        response   = yt_session.delete(delete_url)

        return true
      end

      # Delete a video message
      def delete_message(message_id)
        delete_url = "/feeds/api/users/default/inbox/%s" % message_id
        response   = yt_session.delete(delete_url)

        return true
      end

      def get_upload_token(options, nexturl)
        @opts      = options
        token_body = video_xml
        token_url  = "/action/GetUploadToken"
        response   = yt_session.post(token_url, token_body)

        return {:url    => "#{response.body[/<url>(.+)<\/url>/, 1]}?nexturl=#{nexturl}",
                :token  => response.body[/<token>(.+)<\/token>/, 1]}
      end

      def add_comment(video_id, comment, opts = {})
        reply_to = opts.delete :reply_to
        reply_to = reply_to.unique_id if reply_to.is_a? YouTubeIt::Model::Comment
        comment_body = comment_xml_for(:comment => comment, :reply_to => reply_to_url(video_id, reply_to))
        comment_url  = "/feeds/api/videos/%s/comments" % video_id
        response     = yt_session.post(comment_url, comment_body)
        comment = YouTubeIt::Parser::CommentsFeedParser.new(response.body).parse_single_entry
        return {:code => response.status, :body => response.body, :comment => comment}
      end

      def delete_comment(video_id, comment_id)
        comment_id = comment_id.unique_id if comment_id.is_a? YouTubeIt::Model::Comment
        url  = "/feeds/api/videos/%s/comments/%s" % [video_id, comment_id]
        response     = yt_session.delete(url)

        return response.status == 200
      end

      def comments(video_id, opts = {})
        comment_url = "/feeds/api/videos/%s/comments?" % video_id
        comment_url << opts.collect { |k,p| [k,p].join '=' }.join('&')
        response    = yt_session.get(comment_url)
        return YouTubeIt::Parser::CommentsFeedParser.new(response).parse
      end

      def add_favorite(video_id)
        favorite_body = video_xml_for(:favorite => video_id)
        favorite_url  = "/feeds/api/users/default/favorites"
        response      = yt_session.post(favorite_url, favorite_body)

        return {:code => response.status, :body => response.body, :favorite_entry_id => get_entry_id(response.body)}
      end

      def delete_favorite(video_id)
        favorite_url = "/feeds/api/users/default/favorites/%s" % video_id
        response     = yt_session.delete(favorite_url)

        return true
      end

      def profile(user=nil)
        response    = yt_session.get(profile_url(user))

        return YouTubeIt::Parser::ProfileFeedParser.new(response).parse
      end

      def videos(idxes_to_fetch)
        idxes_to_fetch.each_slice(50).map do |idxes|
          post = Nokogiri::XML <<-BATCH
              <feed
                xmlns='http://www.w3.org/2005/Atom'
                xmlns:media='http://search.yahoo.com/mrss/'
                xmlns:batch='http://schemas.google.com/gdata/batch'
                xmlns:yt='http://gdata.youtube.com/schemas/2007'>
              </feed>
            BATCH
          idxes.each do |idx|
            post.at('feed').add_child <<-ENTRY
              <entry>
                <batch:operation type="query" />
                <id>/feeds/api/videos/#{idx}?v=#{YouTubeIt::API_VERSION}</id>
                <batch:id>#{idx}</batch:id>
              </entry>
            ENTRY
          end

          post_body = StringIO.new('')
          post.write_to( post_body, :indent => 2 )
          post_body_io = StringIO.new(post_body.string)

          response = yt_session.post('feeds/api/videos/batch', post_body_io )
          YouTubeIt::Parser::BatchVideoFeedParser.new(response).parse
        end.reduce({},:merge)
      end

      def profiles(usernames_to_fetch)
        usernames_to_fetch.each_slice(50).map do |usernames|
          post = Nokogiri::XML <<-BATCH
              <feed
                xmlns='http://www.w3.org/2005/Atom'
                xmlns:media='http://search.yahoo.com/mrss/'
                xmlns:batch='http://schemas.google.com/gdata/batch'
                xmlns:yt='http://gdata.youtube.com/schemas/2007'>
              </feed>
            BATCH
          usernames.each do |username|
            post.at('feed').add_child <<-ENTRY
              <entry>
                <batch:operation type="query" />
                <id>#{profile_url(username)}</id>
                <batch:id>#{username}</batch:id>
              </entry>
            ENTRY
          end

          post_body = StringIO.new('')
          post.write_to( post_body, :indent => 2 )
          post_body_io = StringIO.new(post_body.string)

          response = yt_session.post('feeds/api/users/batch', post_body_io )
          YouTubeIt::Parser::BatchProfileFeedParser.new(response).parse
        end.reduce({},:merge)
      end

      def profile_url(user=nil)
        "/feeds/api/users/%s?v=#{YouTubeIt::API_VERSION}" % (user || "default")
      end

      # Return's a user's activity feed.
      def get_activity(user, opts)
        activity_url = "/feeds/api/events?author=%s&v=#{YouTubeIt::API_VERSION}&" % (user ? user : "default")
        activity_url << opts.collect { |k,p| [k,p].join '=' }.join('&')
        response = yt_session.get(activity_url)

        return YouTubeIt::Parser::ActivityParser.new(response).parse
      end

      def watchlater(user)
        watchlater_url = "/feeds/api/users/%s/watch_later?v=#{YouTubeIt::API_VERSION}" % (user ? user : "default")
        response = yt_session.get(watchlater_url)

        return YouTubeIt::Parser::PlaylistFeedParser.new(response).parse
      end

      def add_video_to_watchlater(video_id)
        playlist_body = video_xml_for(:playlist => video_id)
        playlist_url  = "/feeds/api/users/default/watch_later"
        response      = yt_session.post(playlist_url, playlist_body)

        return {:code => response.status, :body => response.body, :watchlater_entry_id => get_entry_id(response.body)}
      end

      def delete_video_from_watchlater(video_id)
        playlist_url = "/feeds/api/users/default/watch_later/%s" % video_id
        response     = yt_session.delete(playlist_url)

        return true
      end

      def playlist(playlist_id, opts = {})
        playlist_url = "/feeds/api/playlists/%s" % playlist_id
        params = {'v' => 2, 'orderby' => 'position'}
        params.merge!(opts) if opts
        playlist_url << "?#{params.collect { |k,v| [k,v].join '=' }.join('&')}"
        response = yt_session.get(playlist_url)

        return YouTubeIt::Parser::PlaylistFeedParser.new(response).parse
      end

      # Fetches playlists for the given user. An optional hash of parameters can be given and will
      # be appended to the request. Paging parameters will need to be used to access playlists
      # beyond the most recent 25 (page size default for YouTube API at the time of this writing)
      # if a user has more than 25 playlists.
      #
      # Paging parameters include the following
      # start-index - 1-based index of which playlist to start from (default is 1)
      # max-results - maximum number of playlists to fetch, up to 25 (default is 25)
      def playlists(user, opts={})
        playlist_url = "/feeds/api/users/%s/playlists" % (user ? user : "default")
        params = {'v' => YouTubeIt::API_VERSION}
        params.merge!(opts) if opts
        playlist_url << "?#{params.collect { |k,v| [k,v].join '=' }.join('&')}"
        response = yt_session.get(playlist_url)

        return YouTubeIt::Parser::PlaylistsFeedParser.new(response).parse
      end

      def add_playlist(options)
        playlist_body = video_xml_for_playlist(options)
        playlist_url  = "/feeds/api/users/default/playlists"
        response      = yt_session.post(playlist_url, playlist_body)

        return YouTubeIt::Parser::PlaylistFeedParser.new(response).parse
      end

      def add_video_to_playlist(playlist_id, video_id, position)
        playlist_body = video_xml_for(:playlist => video_id, :position => position)
        playlist_url  = "/feeds/api/playlists/%s" % playlist_id
        response      = yt_session.post(playlist_url, playlist_body)

        return {:code => response.status, :body => response.body, :playlist_entry_id => get_entry_id(response.body)}
      end

      def update_position_video_from_playlist(playlist_id, playlist_entry_id, position)
        playlist_body = video_xml_for(:position => position)
        playlist_url = "/feeds/api/playlists/%s/%s" % [playlist_id, playlist_entry_id]
        response      = yt_session.put(playlist_url, playlist_body)

        return {:code => response.status, :body => response.body, :playlist_entry_id => get_entry_id(response.body)}
      end

      def update_playlist(playlist_id, options)
        playlist_body = video_xml_for_playlist(options)
        playlist_url  = "/feeds/api/users/default/playlists/%s" % playlist_id
        response      = yt_session.put(playlist_url, playlist_body)

        return YouTubeIt::Parser::PlaylistFeedParser.new(response).parse
      end

      def delete_video_from_playlist(playlist_id, playlist_entry_id)
        playlist_url = "/feeds/api/playlists/%s/%s" % [playlist_id, playlist_entry_id]
        response     = yt_session.delete(playlist_url)

        return true
      end

      def delete_playlist(playlist_id)
        playlist_url = "/feeds/api/users/default/playlists/%s" % playlist_id
        response     = yt_session.delete(playlist_url)

        return true
      end

      def rate_video(video_id, rating)
        rating_body = video_xml_for(:rating => rating)
        rating_url  = "/feeds/api/videos/#{video_id}/ratings"
        response    = yt_session.post(rating_url, rating_body)

        return {:code => response.status, :body => response.body}
      end

      def subscriptions(user)
        subscription_url = "/feeds/api/users/%s/subscriptions?v=#{YouTubeIt::API_VERSION}" % (user ? user : "default")
        response         = yt_session.get(subscription_url)

        return YouTubeIt::Parser::SubscriptionFeedParser.new(response).parse
      end

      def subscribe_channel(channel_name)
        subscribe_body = video_xml_for(:subscribe => channel_name)
        subscribe_url  = "/feeds/api/users/default/subscriptions"
        response       = yt_session.post(subscribe_url, subscribe_body)

        return {:code => response.status, :body => response.body}
      end

      def unsubscribe_channel(subscription_id)
        unsubscribe_url = "/feeds/api/users/default/subscriptions/%s" % subscription_id
        response        = yt_session.delete(unsubscribe_url)

        return {:code => response.status, :body => response.body}
      end

      def favorites(user, opts = {})
        favorite_url = "/feeds/api/users/%s/favorites#{opts.empty? ? '' : '?#{opts.to_param}'}" % (user ? user : "default")
        response     = yt_session.get(favorite_url)

        return YouTubeIt::Parser::VideosFeedParser.new(response.body).parse
      end

      def get_current_user
        current_user_url = "/feeds/api/users/default"
        response         = yt_session.get(current_user_url)

        return Nokogiri::XML(response.body).at("entry/author/name").text
      end

      def add_response(original_video_id, response_video_id)
        response_body   = video_xml_for(:response => response_video_id)
        response_url    = "/feeds/api/videos/%s/responses" % original_video_id
        response        = yt_session.post(response_url, response_body)

        return {:code => response.status, :body => response.body}
      end

      def delete_response(original_video_id, response_video_id)
        response_url    = "/feeds/api/videos/%s/responses/%s" % [original_video_id, response_video_id]
        response        = yt_session.delete(response_url)

        return {:code => response.status, :body => response.body}
      end

      def get_watch_history
        watch_history_url = "/feeds/api/users/default/watch_history?v=#{YouTubeIt::API_VERSION}"
        response = yt_session.get(watch_history_url)

        return YouTubeIt::Parser::VideosFeedParser.new(response.body).parse
      end

      def new_subscription_videos(user)
        subscription_url = "/feeds/api/users/%s/newsubscriptionvideos?v=#{YouTubeIt::API_VERSION}" % (user ? user : "default")
        response         = yt_session.get(subscription_url)

        return YouTubeIt::Parser::VideosFeedParser.new(response.body).parse
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
        header = {"X-GData-Client"  => "#{@client_id}"}
        header.merge!("X-GData-Key" => "key=#{@dev_key}") if @dev_key
        if @authsub_token
          header.merge!("Authorization"  => "AuthSub token=#{@authsub_token}")
        elsif @access_token.nil? && @authsub_token.nil? && @user
          header.merge!("Authorization"  => "GoogleLogin auth=#{auth_token}")
        end
        header
      end

      def parse_upload_error_from(string)
        xml = Nokogiri::XML(string).at('errors')
        if xml
          xml.css("error").inject('') do |all_faults, error|
            if error.at("internalReason")
              msg_error = error.at("internalReason").text
            elsif error.at("location")
              msg_error = error.at("location").text[/media:group\/media:(.*)\/text\(\)/,1]
            else
              msg_error = "Unspecified error"
            end
            code = error.at("code").text if error.at("code")
            all_faults + sprintf("%s: %s\n", msg_error, code)
          end
        else
          string[/<TITLE>(.+)<\/TITLE>/, 1] || string
        end
      end

      def uploaded_video_id_from(string)
        xml = Nokogiri::XML(string)
        xml.at("id").text[/videos\/(.+)/, 1]
      end

      def playlist_id_from(string)
        xml = Nokogiri::XML(string)
        xml.at("entry/id").text[/playlist([^<]+)/, 1].sub(':','')
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
          http  = Faraday.new("https://www.google.com", :ssl => {:verify => false})
          body = "Email=#{YouTubeIt.esc @user}&Passwd=#{YouTubeIt.esc @password}&service=youtube&source=#{YouTubeIt.esc @client_id}"
          response = http.post("/accounts/ClientLogin", body, "Content-Type" => "application/x-www-form-urlencoded")
          raise ::YouTubeIt::AuthenticationError.new(response.body[/Error=(.+)/,1], response.status.to_i) if response.status.to_i != 200
          @auth_token = response.body[/Auth=(.+)/, 1]
        end
      end

      # TODO: isn't there a cleaner way to output top-notch XML without requiring stuff all over the place?
      def video_xml
        b = Builder::XmlMarkup.new
        b.instruct!
        b.entry(:xmlns => "http://www.w3.org/2005/Atom",
          'xmlns:media' => "http://search.yahoo.com/mrss/",
          'xmlns:yt' => "http://gdata.youtube.com/schemas/2007",
          'xmlns:gml' => 'http://www.opengis.net/gml',
          'xmlns:georss' => 'http://www.georss.org/georss') do | m |
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
          if @opts[:latitude] and @opts[:longitude]
            m.tag!("georss:where") do |geo|
              geo.tag!("gml:Point") do |point|
                point.tag!("gml:pos", @opts.values_at(:latitude, :longitude).join(' '))
              end
            end
          end
        end.to_s
      end

      def partial_video_xml(opts)
        perms = [ :rate, :comment, :commentVote, :videoRespond, :list, :embed, :syndicate ]
        delete_attrs = []
        perms.each do |perm|
          delete_attrs << "@action='#{perm}'" if opts[perm]
        end

        entry_attrs = {
          :xmlns => "http://www.w3.org/2005/Atom",
          'xmlns:media' => "http://search.yahoo.com/mrss/",
          'xmlns:gd' => "http://schemas.google.com/g/2005",
          'xmlns:yt' => "http://gdata.youtube.com/schemas/2007",
          'xmlns:gml' => 'http://www.opengis.net/gml',
          'xmlns:georss' => 'http://www.georss.org/georss' }

        if !delete_attrs.empty?
          entry_attrs['gd:fields'] = "yt:accessControl[#{delete_attrs.join(' or ')}]"
        end

        b = Builder::XmlMarkup.new
        b.instruct!
        b.entry(entry_attrs) do | m |

          m.tag!("media:group") do | mg |
            mg.tag!("media:title",        opts[:title], :type => "plain") if opts[:title]
            mg.tag!("media:description",  opts[:description], :type => "plain") if opts[:description]
            mg.tag!("media:keywords",     opts[:keywords].join(",")) if opts[:keywords]
            mg.tag!('media:category',     opts[:category], :scheme => "http://gdata.youtube.com/schemas/2007/categories.cat") if opts[:category]
            mg.tag!('yt:private') if opts[:private]
            mg.tag!('media:category',     opts[:dev_tag], :scheme => "http://gdata.youtube.com/schemas/2007/developertags.cat") if opts[:dev_tag]
          end

          perms.each do |perm|
            m.tag!("yt:accessControl", :action => perm.to_s, :permission => opts[perm]) if opts[perm]
          end

          if opts[:latitude] and opts[:longitude]
            m.tag!("georss:where") do |geo|
              geo.tag!("gml:Point") do |point|
                point.tag!("gml:pos", opts.values_at(:latitude, :longitude).join(' '))
              end
            end
          end
        end.to_s
      end

      def video_xml_for(data)
        b = Builder::XmlMarkup.new
        b.instruct!
        b.entry(:xmlns => "http://www.w3.org/2005/Atom", 'xmlns:yt' => "http://gdata.youtube.com/schemas/2007") do | m |
          m.id(data[:favorite] || data[:playlist] || data[:response]) if data[:favorite] || data[:playlist] || data[:response]
          m.tag!("yt:rating", :value => data[:rating]) if data[:rating]
          m.tag!("yt:position", data[:position]) if data[:position]
          if(data[:subscribe])
            m.category(:scheme => "http://gdata.youtube.com/schemas/2007/subscriptiontypes.cat", :term => "channel")
            m.tag!("yt:username", data[:subscribe])
          end
        end.to_s
      end

      def reply_to_url video_id, reply_to
        'https://gdata.youtube.com/feeds/api/videos/%s/comments/%s' % [video_id, reply_to] if reply_to
      end

      def comment_xml_for(data)
        b = Builder::XmlMarkup.new
        b.instruct!
        b.entry(:xmlns => "http://www.w3.org/2005/Atom", 'xmlns:yt' => "http://gdata.youtube.com/schemas/2007") do | m |
          m.link(:rel => 'http://gdata.youtube.com/schemas/2007#in-reply-to', :type => 'application/atom+xml', :href => data[:reply_to]) if data[:reply_to]
          m.content(data[:comment]) if data[:comment]
        end.to_s
      end

      def message_xml_for(data)
        b = Builder::XmlMarkup.new
        b.instruct!
        b.entry(:xmlns => "http://www.w3.org/2005/Atom", 'xmlns:yt' => "http://gdata.youtube.com/schemas/2007") do | m |
          m.id(data[:vedio_id]) #if data[:vedio_id]
          m.title(data[:title]) if data[:title]
          m.summary(data[:message])
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

      def get_entry_id(string)
        entry_xml = Nokogiri::XML(string)
        entry_xml.css("entry").each do |item|
          return item.at("id").text[/^.*:([^:]+)$/,1]
        end
      end

      def yt_session(url = nil)
        Faraday.new(:url => (url ? url : base_url), :ssl => {:verify => false}) do |builder|
          if @access_token
            if @config_token
              builder.use FaradayMiddleware::YoutubeOAuth, @config_token
            else
              builder.use FaradayMiddleware::YoutubeOAuth2, @access_token
            end
          end
          builder.use FaradayMiddleware::YoutubeAuthHeader, authorization_headers
          builder.use Faraday::Response::YouTubeIt
          builder.adapter Faraday.default_adapter
        end
      end
    end
  end
end
