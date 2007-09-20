class YoutubeG
  module Model
    class Video < YoutubeG::Record
      attr_reader :duration
      attr_reader :format
      attr_reader :noembed
      attr_reader :position
      attr_reader :racy
      attr_reader :statistics
      
      attr_reader :video_id
      attr_reader :published_at
      attr_reader :updated_at
      attr_reader :categories
      attr_reader :keywords
      attr_reader :title
      attr_reader :html_content
      attr_reader :author
      attr_reader :content_url
      attr_reader :player_url
      attr_reader :rating
      attr_reader :view_count

      # TODO:
      # self atom feed
      # alternate youtube watch url
      # responses feed
      # related feed
      # comments feedLink
    end
  end
end
