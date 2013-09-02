class YouTubeIt
  class Error < RuntimeError
    attr_reader :code
    def initialize(msg, code = 0)
      super(msg)
      @code = code
    end
  end

  class ResourceNotFoundError < Error
    def initialize(msg)
      super(msg, 404)
    end
  end

  class UploadError < Error
  end

  class AuthenticationError < Error
  end
end
