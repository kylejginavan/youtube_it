class YouTubeIt
  module Request #:nodoc:
    class UserSearch < BaseSearch #:nodoc:
      include FieldSearch
      attr_reader :max_results                     # max_results
      attr_reader :order_by                        # orderby, ([relevance], viewCount, published, rating)
      attr_reader :offset                          # start-index

      def initialize(params, options={})
        @max_results, @order_by, @offset = nil
        @url = base_url
        @dev_key = options[:dev_key] if options[:dev_key]
        if params == :favorites
          @url << "#{options[:user]}/favorites"
          set_instance_variables(options)
        elsif params[:user] && options[:favorites]
          @url << "#{params[:user]}/favorites"
          set_instance_variables(params)
          return
        elsif params[:user]
          @url << "#{params[:user]}/uploads"
          set_instance_variables(params)
        end

        @url << build_query_params(to_youtube_params)
        @url << fields_to_params(params.delete(:fields)) if params != :favorites && params[:fields]
      end

      private

      def base_url
        super << "users/"
      end

      def to_youtube_params
        {
          'max-results' => @max_results,
          'orderby' => @order_by,
          'start-index' => @offset,
          'v' => 2
        }
      end
    end

  end
end

