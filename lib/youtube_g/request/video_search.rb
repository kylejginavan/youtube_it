class YoutubeG
  module Request
    class VideoSearch < YoutubeG::Record
      # max_results
      attr_reader :max_result_count

      # orderby, ([relevance], viewCount)
      attr_reader :order

      # start-index
      attr_reader :offset

      # vq
      attr_reader :query

      # alt, ([atom], rss, json)
      attr_reader :response_format

      # /-/categories_or_tags
      attr_reader :tags

      # format (1=mobile devices)
      attr_reader :video_format
      
      def base_url
        "http://gdata.youtube.com/feeds/videos"
      end
      
      def is_tag_search?
        !@tags.nil?
      end

      def to_youtube_params
        {
          'max_results' => @max_result_count,
          'orderby' => @order,
          'start-index' => @offset,
          'vq' => @query,
          'alt' => @response_format,
          'format' => @video_format
        }
      end
    end
  end
end
