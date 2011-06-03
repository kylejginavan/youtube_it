require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestVideo < Test::Unit::TestCase
  def test_should_extract_unique_id_from_video_id
    video = YouTubeIt::Model::Video.new(:video_id => "tag:youtube.com,2008:video:ZTUVgYoeN_o")
    assert_equal "ZTUVgYoeN_o", video.unique_id
  end

  def test_should_extract_unique_id_with_hypen_from_video_id
    video = YouTubeIt::Model::Video.new(:video_id => "tag:youtube.com,2008:video:BDqs-OZWw9o")
    assert_equal "BDqs-OZWw9o", video.unique_id
  end

  def test_should_have_related_videos
    video = YouTubeIt::Model::Video.new(:video_id => "tag:youtube.com,2008:video:BDqs-OZWw9o")
    response = video.related

    assert_equal "http://gdata.youtube.com/feeds/api/videos/BDqs-OZWw9o/related", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 25, response.videos.length
    assert_equal 1, response.offset
    assert(response.total_result_count > 0)
    assert_instance_of Time, response.updated_at
  end

  def test_should_have_response_videos
    video = YouTubeIt::Model::Video.new(:video_id => "tag:youtube.com,2008:video:BDqs-OZWw9o")
    response = video.responses

    assert_equal "http://gdata.youtube.com/feeds/api/videos/BDqs-OZWw9o/responses", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 25, response.videos.length
    assert_equal 1, response.offset
    assert(response.total_result_count > 0)
    assert_instance_of Time, response.updated_at
  end

  def test_should_scale_video_embed
    video = YouTubeIt::Model::Video.new(:video_id => "tag:youtube.com,2008:video:EkF4JD2rO3Q", :player_url=>"http://www.youtube.com/v/EkF4JD2rO3Q&feature=youtube_gdata_player", :widescreen => true)
    assert_equal "<object width=\"1280\" height=\"745\">\n<param name=\"movie\" value=\"http://www.youtube.com/v/EkF4JD2rO3Q&feature=youtube_gdata_player\"></param>\n<param name=\"wmode\" value=\"transparent\"></param>\n<embed src=\"http://www.youtube.com/v/EkF4JD2rO3Q&feature=youtube_gdata_player\" type=\"application/x-shockwave-flash\"\nwmode=\"transparent\" width=\"1280\" height=\"745\"></embed>\n</object>\n", video.embed_html_with_width(1280)
  end
end

