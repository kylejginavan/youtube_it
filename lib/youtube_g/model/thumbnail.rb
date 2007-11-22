class YouTubeG
  module Model
    class Thumbnail < YouTubeG::Record
      attr_reader :url
      attr_reader :height
      attr_reader :width
      attr_reader :time
    end
  end
end
