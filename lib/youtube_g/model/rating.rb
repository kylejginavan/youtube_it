class YouTubeG
  module Model
    class Rating < YouTubeG::Record
      # *Float*:: Average rating given to the video
      attr_reader :average
      
      # *Fixnum*:: Maximum rating that can be assigned to the video
      attr_reader :max
      
      # *Fixnum*:: Minimum rating that can be assigned to the video
      attr_reader :min
      
      # *Fixnum*:: Indicates how many people have rated the video
      attr_reader :rater_count
    end
  end
end
