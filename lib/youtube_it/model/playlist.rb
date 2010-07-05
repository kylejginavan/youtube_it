class YouTubeIt
  module Model
    class Playlist < YouTubeIt::Record
      # *String*:: User entered description for the playlist.
      attr_reader :description
    end
  end
end
