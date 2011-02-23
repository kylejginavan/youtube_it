require File.dirname(__FILE__) + '/helper'

class TestVideoFeedParser < Test::Unit::TestCase
  def test_should_parse_likes_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal 1700, video.rating.likes
    end
  end

  def test_should_parse_dislikes_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal 350, video.rating.dislikes
    end
  end

  def with_video_response &block
    File.open(File.dirname(__FILE__) + '/files/youtube_video_response.xml') do |xml|
      parser = YouTubeIt::Parser::VideoFeedParser.new xml.read
      yield parser
    end
  end
end
