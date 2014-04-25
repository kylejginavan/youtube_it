class YouTubeIt
  module Model
    class Playlist < YouTubeIt::Record
      attr_reader :title, :description, :summary, :author, :videos_count, :playlist_id, :xml, :published, :response_code
      def videos
        YouTubeIt::Parser::VideosFeedParser.new(@xml).parse_videos
      end
    end
  end
end

