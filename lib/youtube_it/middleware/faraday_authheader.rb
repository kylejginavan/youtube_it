module Faraday
  class Request::AuthHeader < Faraday::Middleware

    def call(env)
      env[:request_headers].merge!(@headers)
      @app.call(env)
    end

    def initialize(app, headers)
      @app, @headers = app, headers
    end
  end
end