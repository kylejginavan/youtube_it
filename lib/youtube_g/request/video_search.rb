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
      attr_reader :categories

      # format (1=mobile devices)
      attr_reader :video_format
      
      # TODO: Do these belong here?
      attr_reader :url
      
      def initialize(params)
        return if params.nil?

        @url = base_url
        return build_categories(params.delete(:categories)) if params[:categories]

        params.each do |key, value| 
          name = key.to_s
          instance_variable_set("@#{name}", value) if respond_to?(name)
        end
        
        is_tag_search? ? (@url << "/-/#{tags_to_params(@tags)}") : build_url(to_youtube_params)        
      end
      
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
      
      private
        # Convert category symbols into strings and build the URL. GData requires categories to be capitalized. 
        def build_categories(categories)
          @url << "/-/"
          categories.map { |sym| @url << "#{sym.to_s.capitalize}/"  }
        end
        
        def build_url(params)
          @url << '?'
          item_count = 0
          params.keys.each do |key|
            value = params[key]
            next if value.nil?

            @url << '&' if (item_count > 0)
            @url << "#{key}=#{CGI.escape(value.to_s)}"
            item_count += 1
          end
          @url
        end
        
        def tags_to_params(tags)
          tags.map { |t| CGI.escape(t.to_s) }.join("/")
        end
        
    end
  end
end
