class YouTubeIt
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
        qs = params.to_a.map { | k, v | v.nil? ? nil : "#{YouTubeIt.esc(k)}=#{YouTubeIt.esc(v)}" }.compact.sort.join('&')
        qs.empty? ? '' : (@dev_key ? "?#{qs}&key=#{@dev_key}" : "?#{qs}")
      end
    end


    module FieldSearch
      def default_fields
        "id,updated,openSearch:totalResults,openSearch:startIndex,openSearch:itemsPerPage"
      end

      def fields_to_params(fields)
        return "" unless fields

        fields_param = [default_fields]

        if fields[:recorded]
          if fields[:recorded].is_a? Range
            fields_param << "entry[xs:date(yt:recorded) > xs:date('#{formatted_date(fields[:recorded].first)}') and xs:date(yt:recorded) < xs:date('#{formatted_date(fields[:recorded].last)}')]"
          else
            fields_param << "entry[xs:date(yt:recorded) = xs:date('#{formatted_date(fields[:recorded])}')]"
          end
        end

        if fields[:published]
          if fields[:published].is_a? Range
            fields_param << "entry[xs:dateTime(published) > xs:dateTime('#{formatted_date(fields[:published].first)}T00:00:00') and xs:dateTime(published) < xs:dateTime('#{formatted_date(fields[:published].last)}T00:00:00')]"
          else
            fields_param << "entry[xs:date(published) = xs:date('#{formatted_date(fields[:published])}')]"
          end
        end

        if fields[:view_count]
          fields_param << "entry[yt:statistics/@viewCount > #{fields[:view_count]}]"
        end


        return "&fields=#{URI.escape(fields_param.join(","))}"
      end

      #youtube taked dates that look like 'YYYY-MM-DD'
      def formatted_date(date)
        return date if date.is_a? String
        if date.respond_to? :strftime
          date.strftime("%Y-%m-%d")
        else
          ""
        end
      end
    end
  end
end

