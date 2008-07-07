class YouTubeG
  module Model
    class Author < YouTubeG::Record
      # *String*: Author's YouTube username.
      attr_reader :name
      
      # *String*: Feed URL of the author.
      attr_reader :uri
    end
  end
end
