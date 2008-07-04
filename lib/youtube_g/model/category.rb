class YouTubeG
  module Model
    class Category < YouTubeG::Record
      # <String>:: Name of the YouTube category
      attr_reader :label 
      attr_reader :term
    end
  end
end
