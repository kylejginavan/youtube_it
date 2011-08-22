class YouTubeIt
  class Client
    include YouTubeIt::Logging
    # Previously this was a logger instance but we now do it globally

    def initialize *params
      if params.first.is_a?(Hash)
        hash_options = params.first
        @user                  = hash_options[:username]
        @pass                  = hash_options[:password]
        @dev_key               = hash_options[:dev_key]
        @client_id             = hash_options[:client_id] || "youtube_it"
        @legacy_debug_flag     = hash_options[:debug]
      elsif params.first
        puts "* warning: the method YouTubeIt::Client.new(user, passwd, dev_key) is deprecated, use YouTubeIt::Client.new(:username => 'user', :password => 'passwd', :dev_key => 'dev_key')"
        @user               = params.shift
        @pass               = params.shift
        @dev_key            = params.shift
        @client_id          = params.shift || "youtube_it"
        @legacy_debug_flag  = params.shift
      end
    end

    # Retrieves an array of standard feed, custom query, or user videos.
    #
    # === Parameters
    # If fetching videos for a standard feed:
    #   params<Symbol>:: Accepts a symbol of :top_rated, :top_favorites, :most_viewed,
    #                    :most_popular, :most_recent, :most_discussed, :most_linked,
    #                    :most_responded, :recently_featured, and :watch_on_mobile.
    #
    #   You can find out more specific information about what each standard feed provides
    #   by visiting: http://code.google.com/apis/youtube/reference.html#Standard_feeds
    #
    #   options<Hash> (optional)::  Accepts the options of :time, :page (default is 1),
    #                               and :per_page (default is 25). :offset and :max_results
    #                               can also be passed for a custom offset.
    #
    # If fetching videos by tags, categories, query:
    #   params<Hash>:: Accepts the keys :tags, :categories, :query, :order_by,
    #                  :author, :racy, :response_format, :video_format, :page (default is 1),
    #                  and :per_page(default is 25)
    #
    #   options<Hash>:: Not used. (Optional)
    #
    # If fetching videos for a particular user:
    #   params<Hash>:: Key of :user with a value of the username.
    #   options<Hash>:: Not used. (Optional)
    # === Returns
    # YouTubeIt::Response::VideoSearch
    def videos_by(params, options={})
      request_params = params.respond_to?(:to_hash) ? params : options
      request_params[:page] = integer_or_default(request_params[:page], 1)

      request_params[:dev_key] = @dev_key if @dev_key

      unless request_params[:max_results]
        request_params[:max_results] = integer_or_default(request_params[:per_page], 25)
      end

      unless request_params[:offset]
        request_params[:offset] = calculate_offset(request_params[:page], request_params[:max_results] )
      end

      if params.respond_to?(:to_hash) and not params[:user]
        request = YouTubeIt::Request::VideoSearch.new(request_params)
      elsif (params.respond_to?(:to_hash) && params[:user]) || (params == :favorites)
        request = YouTubeIt::Request::UserSearch.new(params, request_params)
      else
        request = YouTubeIt::Request::StandardSearch.new(params, request_params)
      end

      logger.debug "Submitting request [url=#{request.url}]." if @legacy_debug_flag
      parser = YouTubeIt::Parser::VideosFeedParser.new(request.url)
      parser.parse
    end

    # Retrieves a single YouTube video.
    #
    # === Parameters
    #   vid<String>:: The ID or URL of the video that you'd like to retrieve.
    #   user<String>:: The user that uploaded the video that you'd like to retrieve.
    #
    # === Returns
    # YouTubeIt::Model::Video
    def video_by(vid)
      video_id = vid =~ /^http/ ? vid : "http://gdata.youtube.com/feeds/api/videos/#{vid}?v=2#{@dev_key ? '&key='+@dev_key : ''}"
      parser = YouTubeIt::Parser::VideoFeedParser.new(video_id)
      parser.parse
    end

    def video_by_user(user, vid)
      video_id = "http://gdata.youtube.com/feeds/api/users/#{user}/uploads/#{vid}?v=2#{@dev_key ? '&key='+@dev_key : ''}"
      parser = YouTubeIt::Parser::VideoFeedParser.new(video_id)
      parser.parse
    end

    def video_upload(data, opts = {})
      client.upload(data, opts)
    end

    def video_update(video_id, opts = {})
      client.update(video_id, opts)
    end

    def video_delete(video_id)
      client.delete(video_id)
    end

    def upload_token(options, nexturl = "http://www.youtube.com/my_videos")
      client.get_upload_token(options, nexturl)
    end

    def add_comment(video_id, comment)
      client.add_comment(video_id, comment)
    end

    # opts is converted to get params and appended to comments gdata api url
    # eg opts = { 'max-results' => 10, 'start-index' => 20 }
    # hash does _not_ play nice with symbols
    def comments(video_id, opts = {})
      client.comments(video_id, opts)
    end

    def add_favorite(video_id)
      client.add_favorite(video_id)
    end

    def delete_favorite(video_id)
      client.delete_favorite(video_id)
    end

    def favorites(user = nil, opts = {})
      client.favorites(user, opts)
    end

    def profile(user = nil)
      client.profile(user)
    end
    
    # Fetches a user's activity feed.
    def activity(user = nil, opts = {})
      client.get_activity(user, opts)
    end

    def playlist(playlist_id)
      client.playlist playlist_id
    end

    def playlists(user = nil)
      client.playlists(user)
    end

    def add_playlist(options)
      client.add_playlist(options)
    end

    def update_playlist(playlist_id, options)
      client.update_playlist(playlist_id, options)
    end

    def add_video_to_playlist(playlist_id, video_id)
      client.add_video_to_playlist(playlist_id, video_id)
    end

    def delete_video_from_playlist(playlist_id, playlist_entry_id)
      client.delete_video_from_playlist(playlist_id, playlist_entry_id)
    end

    def delete_playlist(playlist_id)
      client.delete_playlist(playlist_id)
    end

    def like_video(video_id)
      client.rate_video(video_id, 'like')
    end

    def dislike_video(video_id)
      client.rate_video(video_id, 'dislike')
    end
    
    def subscribe_channel(channel_name)
      client.subscribe_channel(channel_name)
    end

    def unsubscribe_channel(subscription_id)
      client.unsubscribe_channel(subscription_id)
    end
    
    def subscriptions(user_id = nil)
      client.subscriptions(user_id)
    end

    def enable_http_debugging
      client.enable_http_debugging
    end

    def current_user
      client.get_current_user
    end
    
    # Gets the authenticated users video with the given ID. It may be private.
    def my_video(video_id)
      client.get_my_video(video_id)
    end

    # Gets all videos 
    def my_videos(opts = {})
      client.get_my_videos(opts)
    end
    
    # Get's all of the user's contacts/friends. 
    def my_contacts(opts = {})
      client.get_my_contacts(opts)
    end

    private

    def client
      @client ||= YouTubeIt::Upload::VideoUpload.new(:username => @user, :password => @pass, :dev_key => @dev_key)
    end

    def calculate_offset(page, per_page)
      page == 1 ? 1 : ((per_page * page) - per_page + 1)
    end

    def integer_or_default(value, default)
      value = value.to_i
      value > 0 ? value : default
    end
  end

  class AuthSubClient < Client
    def initialize *params
      if params.first.is_a?(Hash)
        hash_options = params.first
        @authsub_token                 = hash_options[:token]
        @dev_key                       = hash_options[:dev_key]
        @client_id                     = hash_options[:client_id] || "youtube_it"
        @legacy_debug_flag             = hash_options[:debug]
      else
        puts "* warning: the method YouTubeIt::AuthSubClient.new(token, dev_key) is depricated, use YouTubeIt::AuthSubClient.new(:token => 'token', :dev_key => 'dev_key')"
        @authsub_token              = params.shift
        @dev_key                    = params.shift
        @client_id                  = params.shift || "youtube_it"
        @legacy_debug_flag          = params.shift
      end
    end

    def create_session_token
      response = nil
      session_token_url = "/accounts/AuthSubSessionToken"

      http_connection do |session|
        response = session.get2('https://%s' % session_token_url,session_token_header).body
      end
      @authsub_token = response.sub('Token=','')
    end

    def revoke_session_token
      response = nil
      session_token_url = "/accounts/AuthSubRevokeToken"

      http_connection do |session|
        response = session.get2('https://%s' % session_token_url,session_token_header).code
      end
      response.to_s == '200' ? true : false
    end

    def session_token_info
      response = nil
      session_token_url = "/accounts/AuthSubTokenInfo"

      http_connection do |session|
        response = session.get2('https://%s' % session_token_url,session_token_header)
      end
      {:code => response.code, :body => response.body }
    end

    private
      def client
        @client ||= YouTubeIt::Upload::VideoUpload.new(:dev_key => @dev_key, :authsub_token => @authsub_token)
      end

      def session_token_header
        {
          "Content-Type"   => "application/x-www-form-urlencoded",
          "Authorization"  => "AuthSub token=#{@authsub_token}"
        }
      end

      def http_connection
        http = Net::HTTP.new("www.google.com")
        http.set_debug_output(logger) if @http_debugging
        http.start do |session|
          yield(session)
        end
      end
  end

  class OAuthClient < Client
    def initialize *params
      if params.first.is_a?(Hash)
        hash_options = params.first
        @consumer_key                  = hash_options[:consumer_key]
        @consumer_secret               = hash_options[:consumer_secret]
        @user                          = hash_options[:username]
        @dev_key                       = hash_options[:dev_key]
        @client_id                     = hash_options[:client_id] || "youtube_it"
        @legacy_debug_flag             = hash_options[:debug]
      else
        puts "* warning: the method YouTubeIt::OAuthClient.new(consumer_key, consumer_secrect, dev_key) is depricated, use YouTubeIt::OAuthClient.new(:consumer_key => 'consumer key', :consumer_secret => 'consumer secret', :dev_key => 'dev_key')"
        @consumer_key                  = params.shift
        @consumer_secret               = params.shift
        @dev_key                       = params.shift
        @user                          = params.shift
        @client_id                     = params.shift || "youtube_it"
        @legacy_debug_flag             = params.shift
      end
    end

    def consumer
      @consumer ||= ::OAuth::Consumer.new(@consumer_key,@consumer_secret,{
        :site=>"https://www.google.com",
        :request_token_path=>"/accounts/OAuthGetRequestToken",
        :authorize_path=>"/accounts/OAuthAuthorizeToken",
        :access_token_path=>"/accounts/OAuthGetAccessToken"})
    end

    def request_token(callback)
      @request_token = consumer.get_request_token({:oauth_callback => callback},{:scope => "http://gdata.youtube.com"})
    end

    def access_token
      @access_token = ::OAuth::AccessToken.new(consumer, @atoken, @asecret)
    end

    def config_token
      {
        :consumer_key => @consumer_key,
        :consumer_secret => @consumer_secret,
        :token => @atoken,
        :token_secret => @asecret
       }
    end

    def authorize_from_request(rtoken,rsecret,verifier)
      request_token = ::OAuth::RequestToken.new(consumer,rtoken,rsecret)
      access_token = request_token.get_access_token({:oauth_verifier => verifier})
      @atoken,@asecret = access_token.token, access_token.secret
    end

    def authorize_from_access(atoken,asecret)
      @atoken,@asecret = atoken, asecret
    end

    def current_user
      yt_session = Faraday.new(:url => "http://gdata.youtube.com") do |builder|
        builder.use Faraday::Response::YouTubeIt 
        builder.use Faraday::Request::OAuth, config_token
        builder.adapter Faraday.default_adapter          
      end
      
      body = yt_session.get("/feeds/api/users/default").body
      REXML::Document.new(body).elements["entry"].elements['author'].elements['name'].text
    end

    private

    def client
      # IMPORTANT: make sure authorize_from_access is called before client is fetched
      @client ||= YouTubeIt::Upload::VideoUpload.new(:username => current_user, :dev_key => @dev_key, :access_token => access_token, :config_token => config_token)
    end

  end
end

