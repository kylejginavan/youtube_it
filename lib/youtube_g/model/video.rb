# TODO
#  * self atom feed
#  * alternate youtube watch url
#  * comments feedLink

class YouTubeG
  module Model
    class Video < YouTubeG::Record
      # Describes the various file formats in which a Youtube video may be
      # made available and allows looking them up by format code number.
      class Format
        @@formats = Hash.new

        # Instantiates a new video format object.
        #
        # == Parameters
        #   :format_code<Fixnum>:: The Youtube Format code of the object. 
        #   :name<Symbol>:: The name of the format
        #   
        # == Returns
        #   YouTubeG::Model::Video::Format: Video format object
        def initialize(format_code, name)
          @format_code = format_code
          @name = name

          @@formats[format_code] = self          
        end
        
        # Allows you to get the video format for a specific format code.
        # 
        # A full list of format codes is available at:
        # 
        # http://code.google.com/apis/youtube/reference.html#youtube_data_api_tag_media:content
        #
        # == Parameters
        #   :format_code<Fixnum>:: The Youtube Format code of the object. 
        #   
        # == Returns
        #   YouTubeG::Model::Video::Format: Video format object
        def self.by_code(format_code)
          @@formats[format_code]
        end

        # Flash format on YouTube site. All videos are available in this format.
        FLASH = YouTubeG::Model::Video::Format.new(0, :flash)

        # RTSP streaming URL for mobile video playback. H.263 video (176x144) and AMR audio.
        RTSP = YouTubeG::Model::Video::Format.new(1, :rtsp)

        # HTTP URL to the embeddable player (SWF) for this video. This format
        # is not available for a video that is not embeddable.
        SWF = YouTubeG::Model::Video::Format.new(5, :swf)
        
        # RTSP streaming URL for mobile video playback. MPEG-4 SP video (up to 176x144) and AAC audio.
        THREE_GPP = YouTubeG::Model::Video::Format.new(6, :three_gpp)
      end
      
      # *Fixnum*:: Duration of a video in seconds.
      attr_reader :duration
      
      # *Boolean*:: Specifies that a video may or may not be embedded on other websites.
      attr_reader :noembed
      
      # *Fixnum*:: Specifies the order in which the video appears in a playlist.
      attr_reader :position
      
      # *Boolean*:: Specifies that a video is flagged as adult or not.
      attr_reader :racy
      
      # *String*: Specifies a URI that uniquely and permanently identifies the video.
      attr_reader :video_id
      
      # *Time*:: When the video was published on Youtube.
      attr_reader :published_at
      
      # *Time*:: When the video's data was last updated.
      attr_reader :updated_at
      
      # *Array*:: A array of YouTubeG::Model::Category objects that describe the videos categories. 
      attr_reader :categories
      
      # *Array*:: An array of words associated with the video.
      attr_reader :keywords
      
      # *String*:: Description of the video.
      attr_reader :description
      
      # *String*:: Title for the video.
      attr_reader :title
      
      # *String*:: Description of the video.
      attr_reader :html_content
      
      # YouTubeG::Model::Author:: Information about the YouTube user who owns a piece of video content.
      attr_reader :author
      
      # *Array*:: An array of YouTubeG::Model::Content objects describing the individual media content data available for this video.  Most, but not all, videos offer this.
      attr_reader :media_content
      
      # *Array*:: An array of YouTubeG::Model::Thumbnail objects that contain information regarding the videos thumbnail images. 
      attr_reader :thumbnails
      
      # *String*:: The link to watch the URL on YouTubes website.
      attr_reader :player_url
      
      # YouTubeG::Model::Rating:: Information about the videos rating.
      attr_reader :rating
      
      # *Fixnum*:: Number of times that the video has been viewed
      attr_reader :view_count

      # Geodata
      attr_reader :where
      attr_reader :position
      attr_reader :latitude
      attr_reader :longitude
      
      attr_reader :statistics
      
      # Videos related to the current video.
      #
      # === Returns
      #   YouTubeG::Response::VideoSearch
      def related
        YouTubeG::Parser::VideosFeedParser.new("http://gdata.youtube.com/feeds/api/videos/#{unique_id}/related").parse
      end
      
      # Video responses to the current video.
      #
      # === Returns
      #   YouTubeG::Response::VideoSearch   
      def responses
        YouTubeG::Parser::VideosFeedParser.new("http://gdata.youtube.com/feeds/api/videos/#{unique_id}/responses").parse
      end
      
      # The ID of the video, useful for searching for the video again without having to store it anywhere. 
      # A regular query search, with this id will return the same video.
      # 
      # === Example
      #   >> video.unique_id
      #   => "ZTUVgYoeN_o"
      #   
      # === Returns
      #   String: The Youtube video id.
      def unique_id
        video_id[/videos\/([^<]+)/, 1]
      end
      
      # Allows you to check whether the video can be embedded on a webpage.
      #
      # === Returns
      #   Boolean: True if the video can be embedded, false if not.
      def embeddable?
        not @noembed
      end
      
      # Provides a URL and various other types of information about a video.
      # 
      # === Returns
      #   YouTubeG::Model::Content: Data about the embeddable video.
      def default_media_content
        @media_content.find { |c| c.is_default? }
      end
      
      # Gives you the HTML to embed the video on your website.
      #
      # === Returns
      #   String: The HTML for embedding the video on your website.
      def embed_html(width = 425, height = 350)
        <<EDOC
<object width="#{width}" height="#{height}">
  <param name="movie" value="#{embed_url}"></param>
  <param name="wmode" value="transparent"></param>
  <embed src="#{embed_url}" type="application/x-shockwave-flash" 
   wmode="transparent" width="#{width}" height="#{height}"></embed>
</object>
EDOC
      end

      # The URL needed for embedding the video in a page.
      #
      # === Returns
      #   String: Absolute URL for embedding video
      def embed_url
        @player_url.sub('watch?', '').sub('=', '/')          
      end
      
    end
  end
end
