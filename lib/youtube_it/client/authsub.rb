class YouTubeIt::AuthSubClient < YouTubeIt::Client
  def initialize *params
    if params.first.is_a?(Hash)
      hash_options = params.first
      @authsub_token                 = hash_options[:token]
      @dev_key                       = hash_options[:dev_key]
      @client_id                     = hash_options[:client_id] || "youtube_it"
      @legacy_debug_flag             = hash_options[:debug]
    else
      puts "* warning: the method YouTubeIt::AuthSubClient.new(token, dev_key) is depricated, use YouTubeIt::AuthSubClient.new(:token => 'token', :dev_key => 'dev_key')"
      @authsub_token              = params.shift
      @dev_key                    = params.shift
      @client_id                  = params.shift || "youtube_it"
      @legacy_debug_flag          = params.shift
    end
  end

  def create_session_token
    response = nil
    session_token_url = "/accounts/AuthSubSessionToken"

    http_connection do |session|
      response = session.get2('https://%s' % session_token_url,session_token_header).body
    end
    @authsub_token = response.sub('Token=','')
  end

  def revoke_session_token
    response = nil
    session_token_url = "/accounts/AuthSubRevokeToken"

    http_connection do |session|
      response = session.get2('https://%s' % session_token_url,session_token_header).code
    end
    response.to_s == '200' ? true : false
  end

  def session_token_info
    response = nil
    session_token_url = "/accounts/AuthSubTokenInfo"

    http_connection do |session|
      response = session.get2('https://%s' % session_token_url,session_token_header)
    end
    {:code => response.code, :body => response.body }
  end

  private
    def client
      @client ||= YouTubeIt::Upload::VideoUpload.new(:dev_key => @dev_key, :authsub_token => @authsub_token)
    end

    def session_token_header
      {
        "Content-Type"   => "application/x-www-form-urlencoded",
        "Authorization"  => "AuthSub token=#{@authsub_token}"
      }
    end

    def http_connection
      http = Net::HTTP.new("www.google.com")
      http.set_debug_output(logger) if @http_debugging
      http.start do |session|
        yield(session)
      end
    end
end
