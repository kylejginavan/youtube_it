class YouTubeG
  module Model
    class Category < YouTubeG::Record
      attr_reader :label
      attr_reader :term
    end
  end
end
