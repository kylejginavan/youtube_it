class YouTubeG
  module Request #:nodoc: 
    class BaseSearch #:nodoc:
      attr_reader :url
      
      private
      
      def base_url
        "http://gdata.youtube.com/feeds/api/"                
      end
      
      def set_instance_variables( variables )
        variables.each do |key, value| 
          name = key.to_s
          instance_variable_set("@#{name}", value) if respond_to?(name)
        end
      end
      
      def build_query_params(params)
        qs = params.to_a.map { | k, v | v.nil? ? nil : "#{YouTubeG.esc(k)}=#{YouTubeG.esc(v)}" }.compact.sort.join('&')
        qs.empty? ? '' : "?#{qs}"
      end
    end
    
  end
end