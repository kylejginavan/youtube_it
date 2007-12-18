require 'rubygems'
require 'test/unit'
require 'pp'

require 'youtube_g'

class TestVideo < Test::Unit::TestCase

  def test_should_extract_unique_id_from_video_id
    video = YouTubeG::Model::Video.new(:video_id => "http://gdata.youtube.com/feeds/videos/ZTUVgYoeN_o")
    assert_equal "ZTUVgYoeN_o", video.unique_id
  end

  def test_should_extract_unique_id_with_hypen_from_video_id
    video = YouTubeG::Model::Video.new(:video_id => "http://gdata.youtube.com/feeds/videos/BDqs-OZWw9o")
    assert_equal "BDqs-OZWw9o", video.unique_id
  end
end
