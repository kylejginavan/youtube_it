class YouTubeG
  module Response
    class VideoSearch < YouTubeG::Record
      # the unique feed identifying url
      attr_reader :feed_id
      
      # the number of results per page
      attr_reader :max_result_count
      
      # the 1-based offset index into the full result set
      attr_reader :offset
      
      # the total number of results available for the original request
      attr_reader :total_result_count

      # the date and time at which the feed was last updated
      attr_reader :updated_at

      # the list of Video records
      attr_reader :videos
    end
  end
end
