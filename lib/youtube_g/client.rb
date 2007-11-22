require 'logger'

class YouTubeG
  class Client
    attr_accessor :logger
    
    def initialize(logger=Logger.new(STDOUT))
      @logger = logger
    end

    # Params can be one of :most_viewed, :top_rated, :recently_featured, :watch_on_mobile
    # Or :tags, :categories, :query, :user
    def videos_by(params, options={})
      if params.respond_to?(:to_hash) and not params[:user]
        request = YouTubeG::Request::VideoSearch.new(params)

      elsif (params.respond_to?(:to_hash) && params[:user]) || (params == :favorites)
        request = YouTubeG::Request::UserSearch.new(params, options)

      else
        request = YouTubeG::Request::StandardSearch.new(params, options)
      end
      
      logger.debug "Submitting request [url=#{request.url}]."
      parser = YouTubeG::Parser::VideosFeedParser.new(request.url)
      parser.parse
    end
    
    def video_by(video_id)
      parser = YouTubeG::Parser::VideoFeedParser.new(video_id)
      parser.parse
    end
    
  end
end
