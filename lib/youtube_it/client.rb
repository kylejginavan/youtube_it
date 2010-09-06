class YouTubeIt
  class Client
    include YouTubeIt::Logging
    # Previously this was a logger instance but we now do it globally
    def initialize user = nil, pass = nil, dev_key = nil, client_id = 'youtube_it', legacy_debug_flag = nil
      @user, @pass, @dev_key, @client_id = user, pass, dev_key, client_id
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

      logger.debug "Submitting request [url=#{request.url}]."
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
      video_id = vid =~ /^http/ ? vid : "http://gdata.youtube.com/feeds/videos/#{vid}"
      parser = YouTubeIt::Parser::VideoFeedParser.new(video_id)
      parser.parse
    end

    def video_by_user(user, vid)
      video_id = "http://gdata.youtube.com/feeds/api/users/#{user}/uploads/#{vid}"
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

    def enable_http_debugging
      client.enable_http_debugging
    end

    private

    def client
      @client ||= YouTubeIt::Upload::VideoUpload.new(@user, @pass, @dev_key)
    end

    def calculate_offset(page, per_page)
      page == 1 ? 1 : ((per_page * page) - per_page + 1)
    end

    def integer_or_default(value, default)
      value = value.to_i
      value > 0 ? value : default
    end
  end

  class OAuthClient < Client
    def initialize ctoken = nil, csecret = nil, user = nil, dev_key = nil, client_id = 'youtube_it', legacy_debug_flag = nil
      @consumer_key, @consumer_secret, @user, @dev_key, @client_id = ctoken, csecret, user, dev_key, client_id
    end

    def consumer
      @consumer ||= OAuth::Consumer.new(@consumer_key,@consumer_secret,{
        :site=>"https://www.google.com",
        :request_token_path=>"/accounts/OAuthGetRequestToken",
        :authorize_path=>"/accounts/OAuthAuthorizeToken",
        :access_token_path=>"/accounts/OAuthGetAccessToken"})
    end

    def request_token(callback)
      @request_token = consumer.get_request_token({:oauth_callback => callback},{:scope => "http://gdata.youtube.com"})
    end

    def access_token
      @access_token = OAuth::AccessToken.new(consumer, @atoken, @asecret)
    end

    def authorize_from_request(rtoken,rsecret,verifier)
      request_token = OAuth::RequestToken.new(consumer,rtoken,rsecret)
      access_token = request_token.get_access_token({:oauth_verifier => verifier})
      @atoken,@asecret = access_token.token, access_token.secret
    end

    def authorize_from_access(atoken,asecret)
      @atoken,@asecret = atoken, asecret
    end

    private

    def client
      # IMPORTANT: make sure authorize_from_access is called before client is fetched
      @client ||= YouTubeIt::Upload::VideoUpload.new(@user, "", @dev_key, "youtube_it", access_token)
    end

  end
end

