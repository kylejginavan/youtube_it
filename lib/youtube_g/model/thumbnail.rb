class YoutubeG
  module Model
    class Thumbnail < YoutubeG::Record
      attr_reader :url
      attr_reader :height
      attr_reader :width
      attr_reader :time
    end
  end
end
