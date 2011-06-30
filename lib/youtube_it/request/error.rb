class UploadError < YouTubeIt::Error
  attr_reader :code
  def initialize(msg, code = 0)
    super(msg)
    @code = code
  end
end

class AuthenticationError < YouTubeIt::Error
  attr_reader :code
  def initialize(msg, code = 0)
    super(msg)
    @code = code
  end
end