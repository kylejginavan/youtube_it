class YouTubeIt
  module Model
    class Comment < YouTubeIt::Record
      attr_reader :content, :published, :title, :updated, :url

      # YouTubeIt::Model::Author:: Information about the YouTube user who owns a piece of video content.
      attr_reader :author
      
      # unique ID of the comment.
      def unique_id
        url.split("/").last
      end
    end
  end
end

