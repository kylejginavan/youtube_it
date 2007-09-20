class YoutubeG
  class Client
    
    def videos_by(options)
      query = options.delete(:query)
      request = YoutubeG::Request::VideoSearch.new(:query => query)
      search_videos(request)
    end
    
  end
end