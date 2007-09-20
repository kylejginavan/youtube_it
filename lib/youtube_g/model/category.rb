class YoutubeG
  module Model
    class Category < YoutubeG::Record
      attr_reader :label
      attr_reader :term
    end
  end
end
