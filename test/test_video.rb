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

  def test_should_have_related_videos
    video = YouTubeG::Model::Video.new(:video_id => "http://gdata.youtube.com/feeds/videos/BDqs-OZWw9o")
    response = video.related

    assert_equal "http://gdata.youtube.com/feeds/api/videos/BDqs-OZWw9o/related", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 25, response.videos.length
    assert_equal 1, response.offset
    assert(response.total_result_count > 0)
    assert_instance_of Time, response.updated_at
  end
  
  def test_should_have_response_videos
    video = YouTubeG::Model::Video.new(:video_id => "http://gdata.youtube.com/feeds/videos/BDqs-OZWw9o")
    response = video.responses

    assert_equal "http://gdata.youtube.com/feeds/api/videos/BDqs-OZWw9o/responses", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 25, response.videos.length
    assert_equal 1, response.offset
    assert(response.total_result_count > 0)
    assert_instance_of Time, response.updated_at
  end
  
end
