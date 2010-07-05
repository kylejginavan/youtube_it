class YouTubeIt
  module Model
    class Author < YouTubeIt::Record
      # *String*: Author's YouTube username.
      attr_reader :name
      
      # *String*: Feed URL of the author.
      attr_reader :uri
    end
  end
end
