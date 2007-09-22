class YoutubeG
  
  # The goal of the classes in this module is to build the request URLs for each type of search
  module Request
    
    class VideoSearch < YoutubeG::Record
      attr_reader :max_result_count                # max_results
      attr_reader :order                           # orderby, ([relevance], viewCount)
      attr_reader :offset                          # start-index
      attr_reader :query                           # vq
      attr_reader :response_format                 # alt, ([atom], rss, json)
      attr_reader :tags                            # /-/tag1/tag2
      attr_reader :categories                      # /-/Category1/Category2
      attr_reader :video_format                    # format (1=mobile devices)
      
      attr_reader :url
      
      def initialize(params)
        return if params.nil?

        @url = base_url
        @url << "/-/" if (params[:categories] || params[:tags])
        @url << categories_to_params(params.delete(:categories)) << "/" if params[:categories]
        @url << tags_to_params(params.delete(:tags)) if params[:tags]

        params.each do |key, value| 
          name = key.to_s
          instance_variable_set("@#{name}", value) if respond_to?(name)
        end
        
        @url << build_url(to_youtube_params) if params[:query]  
      end
      
      def base_url
        "http://gdata.youtube.com/feeds/videos"
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
        def categories_to_params(categories)
          categories.map { |c| c.to_s.capitalize }.join("/")
        end
        
        def tags_to_params(tags)
          tags.map { |t| CGI.escape(t.to_s) }.join("/")
        end

        def build_url(params)
          u = '?'
          item_count = 0
          params.keys.each do |key|
            value = params[key]
            next if value.nil?

            u << '&' if (item_count > 0)
            u << "#{key}=#{CGI.escape(value.to_s)}"
            item_count += 1
          end
          u
        end
        
    end
  end
end
