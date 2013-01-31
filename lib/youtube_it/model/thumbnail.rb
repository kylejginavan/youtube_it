class YouTubeIt
  module Model
    class Thumbnail < YouTubeIt::Record
      # *String*:: URL for the thumbnail image.
      attr_reader :url
      
      # *Fixnum*:: Height of the thumbnail image.
      attr_reader :height
      
      # *Fixnum*:: Width of the thumbnail image.
      attr_reader :width
      
      # *String*:: Specifies the time offset at which the frame shown in the thumbnail image appears in the video.
      attr_reader :time

      # *String*:: Specified type of the thumbnail, attribute yt:name in feed
      attr_reader :name
    end
  end
end
