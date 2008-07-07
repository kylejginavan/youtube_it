class YouTubeG
  module Model
    class Playlist < YouTubeG::Record
      # *String*:: User entered description for the playlist.
      attr_reader :description
    end
  end
end
