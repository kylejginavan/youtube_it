module Faraday
  class Response::YouTubeIt < Response::Middleware
    def parse_upload_error_from(string)
      begin
        REXML::Document.new(string).elements["//errors"].inject('') do | all_faults, error|
          if error.elements["internalReason"]
            msg_error = error.elements["internalReason"].text
          elsif error.elements["location"]
            msg_error = error.elements["location"].text[/media:group\/media:(.*)\/text\(\)/,1]
          else
            msg_error = "Unspecified error"
          end
          code = error.elements["code"].text if error.elements["code"]
          all_faults + sprintf("%s: %s\n", msg_error, code)
        end
      rescue
        string[/<TITLE>(.+)<\/TITLE>/, 1] || string
      end
    end

    def on_complete(env) #this method is called after finish request
      msg = parse_upload_error_from(env[:body].gsub(/\n/, ''))
      if env[:status] == 403 || env[:status] == 401
        raise ::AuthenticationError.new(msg, env[:status])
      elsif env[:status] / 10 != 20
        raise ::UploadError.new(msg, env[:status])
      end
    end
  end
end
