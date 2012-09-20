class YouTubeIt
  module Model
    class Caption < YouTubeIt::Record
      attr_reader :id, :title, :published
    end
  end
end
