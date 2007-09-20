class YoutubeG
  module Model
    class Video < YoutubeG::Record
      # Describes the various file formats in which a Youtube video may be
      # made available and allows looking them up by format code number.
      #
      class Format
        @@formats = Hash.new

        def initialize (format_code, name)
          @format_code = format_code
          @name = name

          @@formats[format_code] = self
        end

        def self.by_code (format_code)
          @@formats[format_code]
        end

        # Flash format on YouTube site. All videos are available in this
        # format.
        #
        FLASH = YoutubeG::Model::Video::Format.new(0, :flash)

        # RTSP streaming URL for mobile video playback. H.263 video (176x144)
        # and AMR audio.
        #
        RTSP = YoutubeG::Model::Video::Format.new(1, :rtsp)

        # HTTP URL to the embeddable player (SWF) for this video. This format
        # is not available for a video that is not embeddable.
        #
        SWF = YoutubeG::Model::Video::Format.new(5, :swf)
      end

      attr_reader :duration
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

      # YoutubeG::Model::Content records describing the individual media content
      # data available for this video.  Most, but not all, videos offer this.
      attr_reader :media_content

      attr_reader :player_url
      attr_reader :rating
      attr_reader :view_count

      # TODO:
      # self atom feed
      # alternate youtube watch url
      # responses feed
      # related feed
      # comments feedLink
      
      def default_media_content
        @media_content.find { |c| c.is_default? }
      end
    end
  end
end
