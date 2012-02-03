require "oauth2"

class YouTubeIt::OAuth2Client < YouTubeIt::Client
  def initialize(options)
    @client_id            = options[:client_id]
    @client_secret        = options[:client_secret]
    @client_access_token  = options[:client_access_token]
    @client_refresh_token = options[:client_refresh_token]
    @dev_key              = options[:dev_key]
  end

  def oauth_client
    @oauth_client ||= ::OAuth2::Client.new(@client_id, @client_secret,
                                           :site => "https://accounts.google.com",
                                           :authorize_url => '/o/oauth2/auth',
                                           :token_url => '/o/oauth2/token')
  end
  
  def access_token
    @access_token ||= ::OAuth2::AccessToken.new(oauth_client, @client_access_token, :refresh_token => @client_refresh_token)
  end

  def refresh_access_token!
    @access_token = access_token.refresh!
  end

  def current_user
    profile = access_token.get("http://gdata.youtube.com/feeds/api/users/default")
    response_code = profile.status

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
    @client ||= YouTubeIt::Upload::VideoUpload.new(:username => current_user, :access_token => access_token, :dev_key => @dev_key)
  end
end
