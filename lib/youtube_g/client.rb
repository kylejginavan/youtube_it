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
    #   options<Hash>::  Accepts the options of :time, :offset, and :max_results. (Optional)
    #   
    # If fetching videos by tags, categories, query:
    #   params<Hash>:: Accepts the keys :tags, :categories, :query, :order_by, 
    #                  :author, :racy, :response_format, :video_format, :offset, 
    #                  and :max_results.
    #                  
    #   options<Hash>:: Not used. (Optional)
    # 
    # If fetching videos for a particular user:
    #   params<Hash>:: Key of :user with a value of the username.
    #   options<Hash>:: Not used. (Optional)
    # === Returns
    # YouTubeG::Response::VideoSearch
    def videos_by(params, options={})
      if params.respond_to?(:to_hash) and not params[:user]
        request = YouTubeG::Request::VideoSearch.new(params)
      elsif (params.respond_to?(:to_hash) && params[:user]) || (params == :favorites)
        request = YouTubeG::Request::UserSearch.new(params, options)
      else
        request = YouTubeG::Request::StandardSearch.new(params, options)
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
    
  end
end
