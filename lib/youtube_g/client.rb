require 'logger'

class YouTubeG
  class Client
    attr_accessor :logger
    
    def initialize(logger=false)
      @logger = Logger.new(STDOUT) if logger
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
      
      logger.debug "Submitting request [url=#{request.url}]." if logger
      parser = YouTubeG::Parser::VideosFeedParser.new(request.url)
      parser.parse
    end
    
    def video_by(vid)
      video_id = vid =~ /^http/ ? vid : "http://gdata.youtube.com/feeds/videos/#{vid}"
      parser = YouTubeG::Parser::VideoFeedParser.new(video_id)
      parser.parse
    end
    
  end
end
