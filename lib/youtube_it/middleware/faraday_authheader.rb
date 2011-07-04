module Faraday
  class Request::AuthHeader < Faraday::Middleware

    def call(env)
      req_headers = env[:request_headers]
      req_headers.merge!(@headers)
      unless req_headers.include?("GData-Version")
        req_headers.merge!("GData-Version" => "2")
      end
      unless req_headers.include?("Content-Type")
        req_headers.merge!("Content-Type"  => "application/atom+xml; charset=UTF-8")
      end
      unless req_headers.include?("Content-Length")
        req_headers.merge!("Content-Length"  => env[:body] ? "#{env[:body].length}" : "0")
      end

      @app.call(env)
    end

    def initialize(app, headers)
      @app, @headers = app, headers
    end
  end
end