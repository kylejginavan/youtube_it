class YouTubeG
  module Response
    class VideoSearch < YouTubeG::Record
      # *String*:: Unique feed identifying url.
      attr_reader :feed_id 
      
      # *Fixnum*:: Number of results per page.
      attr_reader :max_result_count
      
      # *Fixnum*:: 1-based offset index into the full result set.
      attr_reader :offset
      
      # *Fixnum*:: Total number of results available for the original request.
      attr_reader :total_result_count

      # *Time*:: Date and time at which the feed was last updated
      attr_reader :updated_at

      # *Array*:: Array of YouTubeG::Model::Video records
      attr_reader :videos
    end
  end
end
