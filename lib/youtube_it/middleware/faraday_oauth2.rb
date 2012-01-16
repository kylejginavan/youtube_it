module Faraday
  class Request::OAuth2 < Faraday::Middleware
    def call(env)
      env[:request_headers]['Authorization'] = "Bearer #{@access_token.token}"

      @app.call(env)
    end

    def initialize(app, access_token)
      @app, @access_token = app, access_token
    end
  end
end
