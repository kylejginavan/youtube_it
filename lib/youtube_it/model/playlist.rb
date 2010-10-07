class YouTubeIt
  module Model
    class Playlist < YouTubeIt::Record
      attr_reader :title, :description, :summary, :playlist_id
    end
  end
end

