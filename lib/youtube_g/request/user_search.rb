class YouTubeG
  module Request #:nodoc:  
    class UserSearch < BaseSearch #:nodoc:      
      attr_reader :max_results                     # max_results
      attr_reader :order_by                        # orderby, ([relevance], viewCount, published, rating)
      attr_reader :offset                          # start-index

      def initialize(params, options={})
        @max_results, @order_by, @offset = nil
        @url = base_url

        if params == :favorites
          @url << "#{options[:user]}/favorites" 
          set_instance_variables(options)
        elsif params[:user]
          @url << "#{params[:user]}/uploads"
          set_instance_variables(params)
        end
        
        @url << build_query_params(to_youtube_params)
      end

      private

      def base_url #:nodoc:
        super << "users/"
      end

      def to_youtube_params #:nodoc:
        {
          'max-results' => @max_results,
          'orderby' => @order_by,
          'start-index' => @offset
        }
      end
    end
    
  end
end