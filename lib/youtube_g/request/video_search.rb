class YouTubeG
  module Request #:nodoc:    
    class VideoSearch < BaseSearch #:nodoc:
      # From here: http://code.google.com/apis/youtube/reference.html#yt_format
      ONLY_EMBEDDABLE = 5

      attr_reader :max_results                     # max_results
      attr_reader :order_by                        # orderby, ([relevance], viewCount, published, rating)
      attr_reader :offset                          # start-index
      attr_reader :query                           # vq
      attr_reader :response_format                 # alt, ([atom], rss, json)
      attr_reader :tags                            # /-/tag1/tag2
      attr_reader :categories                      # /-/Category1/Category2
      attr_reader :video_format                    # format (1=mobile devices)
      attr_reader :racy                            # racy ([exclude], include)
      attr_reader :author
      
      def initialize(params={})
        # Initialize our various member data to avoid warnings and so we'll
        # automatically fall back to the youtube api defaults
        @max_results, @order_by, 
        @offset, @query, 
        @response_format, @video_format, 
        @racy, @author = nil
        @url = base_url
        
        # Return a single video (base_url + /T7YazwP8GtY)
        return @url << "/" << params[:video_id] if params[:video_id]
        
        @url << "/-/" if (params[:categories] || params[:tags])
        @url << categories_to_params(params.delete(:categories)) if params[:categories]
        @url << tags_to_params(params.delete(:tags)) if params[:tags]

        set_instance_variables(params)
        
        if( params[ :only_embeddable ] )
          @video_format = ONLY_EMBEDDABLE
        end

        @url << build_query_params(to_youtube_params)
      end
      
      private
      
      def base_url
        super << "videos"
      end
      
      def to_youtube_params
        {
          'max-results' => @max_results,
          'orderby' => @order_by,
          'start-index' => @offset,
          'vq' => @query,
          'alt' => @response_format,
          'format' => @video_format,
          'racy' => @racy,
          'author' => @author
        }
      end

      # Convert category symbols into strings and build the URL. GData requires categories to be capitalized. 
      # Categories defined like: categories => { :include => [:news], :exclude => [:sports], :either => [..] }
      # or like: categories => [:news, :sports]
      def categories_to_params(categories)
        if categories.respond_to?(:keys) and categories.respond_to?(:[])
          s = ""
          s << categories[:either].map { |c| c.to_s.capitalize }.join("%7C") << '/' if categories[:either]
          s << categories[:include].map { |c| c.to_s.capitalize }.join("/") << '/' if categories[:include]            
          s << ("-" << categories[:exclude].map { |c| c.to_s.capitalize }.join("/-")) << '/' if categories[:exclude]
          s
        else
          categories.map { |c| c.to_s.capitalize }.join("/") << '/'
        end
      end

      # Tags defined like: tags => { :include => [:football], :exclude => [:soccer], :either => [:polo, :tennis] }
      # or tags => [:football, :soccer]
      def tags_to_params(tags)
        if tags.respond_to?(:keys) and tags.respond_to?(:[])
          s = ""
          s << tags[:either].map { |t| YouTubeG.esc(t.to_s) }.join("%7C") << '/' if tags[:either]
          s << tags[:include].map { |t| YouTubeG.esc(t.to_s) }.join("/") << '/' if tags[:include]            
          s << ("-" << tags[:exclude].map { |t| YouTubeG.esc(t.to_s) }.join("/-")) << '/' if tags[:exclude]
          s
        else
          tags.map { |t| YouTubeG.esc(t.to_s) }.join("/") << '/'
        end          
      end
        
    end
  end
end
