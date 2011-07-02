class YouTubeIt
  module Model
    class Subscription < YouTubeIt::Record
      attr_reader :id, :title, :published
    end
  end
end
