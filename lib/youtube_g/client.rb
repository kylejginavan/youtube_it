class YoutubeG
  class Client
    attr_accessor :logger

    def logger
      @logger = YoutubeG::Logger.new(STDOUT) if !@logger
    end

    def videos_by(params, options={})
      if params.is_a?(Hash)
        request = YoutubeG::Request::VideoSearch.new(params)
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
