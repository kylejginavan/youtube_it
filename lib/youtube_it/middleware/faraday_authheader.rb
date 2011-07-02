module Faraday
  class Request::AuthHeader < Faraday::Middleware

    def call(env)
      req_headers = env[:request_headers]
      req_headers.merge!(@headers)
      req_headers.merge!("GData-Version" => "2") unless req_headers.include?("GData-Version")
      @app.call(env)
    end

    def initialize(app, headers)
      @app, @headers = app, headers
    end
  end
end