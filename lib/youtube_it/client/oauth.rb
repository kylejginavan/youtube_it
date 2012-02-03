require "oauth"
require "simple_oauth"

class YouTubeIt::OAuthClient < YouTubeIt::Client
  def initialize *params
    if params.first.is_a?(Hash)
      hash_options = params.first
      @consumer_key                  = hash_options[:consumer_key]
      @consumer_secret               = hash_options[:consumer_secret]
      @user                          = hash_options[:username]
      @dev_key                       = hash_options[:dev_key]
      @client_id                     = hash_options[:client_id] || "youtube_it"
      @legacy_debug_flag             = hash_options[:debug]
    else
      puts "* warning: the method YouTubeIt::OAuthClient.new(consumer_key, consumer_secrect, dev_key) is depricated, use YouTubeIt::OAuthClient.new(:consumer_key => 'consumer key', :consumer_secret => 'consumer secret', :dev_key => 'dev_key')"
      @consumer_key                  = params.shift
      @consumer_secret               = params.shift
      @dev_key                       = params.shift
      @user                          = params.shift
      @client_id                     = params.shift || "youtube_it"
      @legacy_debug_flag             = params.shift
    end
  end

  def consumer
    @consumer ||= ::OAuth::Consumer.new(@consumer_key,@consumer_secret,{
      :site=>"https://www.google.com",
      :request_token_path=>"/accounts/OAuthGetRequestToken",
      :authorize_path=>"/accounts/OAuthAuthorizeToken",
      :access_token_path=>"/accounts/OAuthGetAccessToken"})
  end

  def request_token(callback)
    @request_token = consumer.get_request_token({:oauth_callback => callback},{:scope => "http://gdata.youtube.com"})
  end

  def access_token
    @access_token = ::OAuth::AccessToken.new(consumer, @atoken, @asecret)
  end

  def config_token
    {
      :consumer_key => @consumer_key,
      :consumer_secret => @consumer_secret,
      :token => @atoken,
      :token_secret => @asecret
     }
  end

  def authorize_from_request(rtoken,rsecret,verifier)
    request_token = ::OAuth::RequestToken.new(consumer,rtoken,rsecret)
    access_token = request_token.get_access_token({:oauth_verifier => verifier})
    @atoken,@asecret = access_token.token, access_token.secret
  end

  def authorize_from_access(atoken,asecret)
    @atoken,@asecret = atoken, asecret
  end

  def current_user
    profile = access_token.get("http://gdata.youtube.com/feeds/api/users/default")
    response_code = profile.code.to_i

    if response_code/10 == 20 # success
      REXML::Document.new(profile.body).elements["entry"].elements['author'].elements['name'].text
    elsif response_code == 403 || response_code == 401 # auth failure
      raise YouTubeIt::Upload::AuthenticationError.new(profile.inspect, response_code)
    else
      raise YouTubeIt::Upload::UploadError.new(profile.inspect, response_code)
    end
  end

  private
  def client
    # IMPORTANT: make sure authorize_from_access is called before client is fetched
    @client ||= YouTubeIt::Upload::VideoUpload.new(:username => current_user, :dev_key => @dev_key, :access_token => access_token, :config_token => config_token)
  end
end
