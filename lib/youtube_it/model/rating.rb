class YouTubeIt
  module Model
    class Rating < YouTubeIt::Record
      # *Float*:: Average rating given to the video
      attr_reader :average
      
      # *Fixnum*:: Maximum rating that can be assigned to the video
      attr_reader :max
      
      # *Fixnum*:: Minimum rating that can be assigned to the video
      attr_reader :min
      
      # *Fixnum*:: Indicates how many people have rated the video
      attr_reader :rater_count

      # *Fixnum*:: Indicates how many people likes this video
      attr_reader :likes

      # *Fixnum*:: Indicates how many people dislikes this video
      attr_reader :dislikes
    end
  end
end
