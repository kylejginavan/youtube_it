class YoutubeG
  module Model
    class Author < YoutubeG::Record
      attr_reader :name
      attr_reader :uri
    end
  end
end
