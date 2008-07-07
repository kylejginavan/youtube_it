class YouTubeG
  module Model
    class Thumbnail < YouTubeG::Record
      # *String*:: URL for the thumbnail image.
      attr_reader :url
      
      # *Fixnum*:: Height of the thumbnail image.
      attr_reader :height
      
      # *Fixnum*:: Width of the thumbnail image.
      attr_reader :width
      
      # *String*:: Specifies the time offset at which the frame shown in the thumbnail image appears in the video.
      attr_reader :time
    end
  end
end
