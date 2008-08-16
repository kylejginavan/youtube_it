class YouTubeG
  class Client
    attr_accessor :logger
    
    def initialize(logger=false)
      @logger = Logger.new(STDOUT) if logger
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
    # YouTubeG::Response::VideoSearch
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
        request = YouTubeG::Request::VideoSearch.new(request_params)
      elsif (params.respond_to?(:to_hash) && params[:user]) || (params == :favorites)
        request = YouTubeG::Request::UserSearch.new(request_params, options)
      else
        request = YouTubeG::Request::StandardSearch.new(params, request_params)
      end
      
      logger.debug "Submitting request [url=#{request.url}]." if logger
      parser = YouTubeG::Parser::VideosFeedParser.new(request.url)
      parser.parse
    end
    
    # Retrieves a single YouTube video.
    #
    # === Parameters
    #   vid<String>:: The ID or URL of the video that you'd like to retrieve.
    # 
    # === Returns
    # YouTubeG::Model::Video
    def video_by(vid)
      video_id = vid =~ /^http/ ? vid : "http://gdata.youtube.com/feeds/videos/#{vid}"
      parser = YouTubeG::Parser::VideoFeedParser.new(video_id)
      parser.parse
    end
    
    private
    
    def calculate_offset(page, per_page)
      page == 1 ? 1 : ((per_page * page) - per_page + 1)
    end
    
    def integer_or_default(value, default)
      value = value.to_i
      value > 0 ? value : default
    end
  end
end
