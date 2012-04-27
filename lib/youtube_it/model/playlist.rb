class YouTubeIt
  module Model
    class Playlist < YouTubeIt::Record
      attr_reader :title, :description, :summary, :playlist_id, :xml, :published, :response_code
      def videos(order_by = :position)
        playlist_url = "/feeds/api/playlists/%s?v=2&orderby=%s" % [playlist_id, order_by]
        YouTubeIt::Parser::VideosFeedParser.new("http://gdata.youtube.com/#{playlist_url}").parse_videos
      end
    end
  end
end

