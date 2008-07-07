class YouTubeG
  module Request #:nodoc:  
    class UserSearch < BaseSearch #:nodoc:      
      def initialize(params, options={})
        @url = base_url
        return @url << "#{options[:user]}/favorites" if params == :favorites
        @url << "#{params[:user]}/uploads" if params[:user]
      end

      private

      def base_url #:nodoc:
        super << "users/"
      end
    end
    
  end
end