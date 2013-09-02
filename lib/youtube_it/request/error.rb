class YouTubeIt
  class Error < RuntimeError
    attr_reader :code
    def initialize(msg, code = 0)
      super(msg)
      @code = code
    end
  end

  class UploadError < Error
  end

  class AuthenticationError < Error
  end
end
