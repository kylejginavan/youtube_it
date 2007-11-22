class YouTubeG
  module Model
    class Rating < YouTubeG::Record
      attr_reader :average
      attr_reader :max
      attr_reader :min
      attr_reader :rater_count
    end
  end
end
