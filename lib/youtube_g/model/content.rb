class YouTubeG
  module Model
    class Content < YouTubeG::Record
      # *Boolean*:: Description of the video.
      attr_reader :default
      # *Fixnum*:: Length of the video in seconds.
      attr_reader :duration
      # YouTubeG::Model::Video::Format:: Specifies the video format of the video object
      attr_reader :format
      # *String*:: Specifies the MIME type of the media object.
      attr_reader :mime_type
      # *String*:: Specifies the URL for the media object.
      attr_reader :url
      
      alias :is_default? :default
    end
  end
end
