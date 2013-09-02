module Faraday
  class Response::YouTubeIt < Response::Middleware
    def on_complete(env) #this method is called after finish request
      msg = parse_error_from(env[:body])
      if env[:status] == 404
        raise ::YouTubeIt::ResourceNotFoundError.new(msg)
      elsif env[:status] == 403 || env[:status] == 401
        raise ::YouTubeIt::AuthenticationError.new(msg, env[:status])
      elsif (env[:status] / 10).to_i != 20
        raise ::YouTubeIt::UploadError.new(msg, env[:status])
      end
    end

    private
    def parse_error_from(string)
      return "" unless string

      string.gsub!("\n", "")

      xml = Nokogiri::XML(string).at('errors')
      if xml
        xml.css("error").inject('') do |all_faults, error|
          if error.at("internalReason")
            msg_error = error.at("internalReason").text
          elsif error.at("location")
            msg_error = error.at("location").text[/media:group\/media:(.*)\/text\(\)/,1]
          else
            msg_error = "Unspecified error"
          end
          code = error.at("code").text if error.at("code")
          all_faults + sprintf("%s: %s\n", msg_error, code)
        end
      else
        string[/<TITLE>(.+)<\/TITLE>/, 1] || string
      end
    end
  end
end
