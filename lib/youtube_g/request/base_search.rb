class YouTubeG
  module Request #:nodoc: 
    class BaseSearch #:nodoc:
      attr_reader :url

      private

      def base_url #:nodoc:
        "http://gdata.youtube.com/feeds/api/"                
      end

      def set_instance_variables( variables ) #:nodoc:
        variables.each do |key, value| 
          name = key.to_s
          instance_variable_set("@#{name}", value) if respond_to?(name)
        end
      end

      def build_query_params(params) #:nodoc:
        # nothing to do if there are no params
        return '' if (!params || params.empty?)

        # build up the query param string, tacking on every key/value
        # pair for which the value is non-nil
        u = '?'
        item_count = 0
        params.keys.sort.each do |key|
          value = params[key]
          next if value.nil?

          u << '&' if (item_count > 0)
          u << "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
          item_count += 1
        end

        # if we found no non-nil values, we've got no params so just
        # return an empty string
        (item_count == 0) ? '' : u
      end
    end
    
  end
end