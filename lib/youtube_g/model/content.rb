class YoutubeG
  module Model
    class Content < YoutubeG::Record
      attr_reader :default
      attr_reader :duration
      attr_reader :format
      attr_reader :mime_type
      attr_reader :url
      
      alias :is_default? :default
    end
  end
end
