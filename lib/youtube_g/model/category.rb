class YouTubeG
  module Model
    class Category < YouTubeG::Record
      # *String*:: Name of the YouTube category
      attr_reader :label 
      
      # *String*:: Identifies the type of item described.
      attr_reader :term
    end
  end
end
