class YouTubeIt
  module Model
    class Activity < YouTubeIt::Record
      # Attributes common to multiple activity types
      attr_reader :type, :author, :videos, :video_id, :time
      
      # video_rated
      attr_reader :user_rating, :video_rating
      
      # video_commented
      attr_reader :comment_thread_url, :video_url
      
      # friend_added and user_subscription_added
      attr_reader :username
    end
  end
end
