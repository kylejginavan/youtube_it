class YoutubeG
  class Client
    attr_accessor :logger

    def logger
      @logger = YoutubeG::Logger.new(STDOUT) if !@logger
    end

    # Params can be one of :most_viewed, :top_rated, :recently_featured, :watch_on_mobile
    # Or :tags, :categories, :query, :user
    def videos_by(params, options={})
      if params.respond_to?(:keys) and params.respond_to?(:[])
        request = YoutubeG::Request::VideoSearch.new(params)
      elsif params.respond_to?(:keys) and params[:user]
        request = YoutubeG::Request::UserSearch.new(params)
      else
        request = YoutubeG::Request::StandardSearch.new(params, options)
      end
      
      logger.debug "Submitting request [url=#{request.url}]."
      parser = YoutubeG::Parser::VideoFeedParser.new(request.url)
      parser.parse
    end
    
    # def favorite_videos_for(params)
    #   
    # end
    
  end
end
