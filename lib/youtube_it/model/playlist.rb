class YouTubeIt
  module Model
    class Playlist < YouTubeIt::Record
      attr_reader :title, :description, :summary, :playlist_id, :xml, :published, :response_code
      def videos
        YouTubeIt::Parser::VideosFeedParser.new("http://gdata.youtube.com/feeds/api/playlists/#{playlist_id}?v=2").parse_videos
      end
    end
  end
end

