require 'rubygems'
require 'test/unit'
require 'pp'

require 'youtube_g'

class TestVideoSearch < Test::Unit::TestCase
  def setup
    @client = YoutubeG::Client.new
  end

  def test_should_respond_to_a_basic_query
    request = YoutubeG::Request::VideoSearch.new(:query => "christina ricci")
    response = @client.search_videos request
    # pp response
    
    assert_equal "http://gdata.youtube.com/feeds/videos", response.feed_id
    # assert_equal 25, response.videos.size
    
    test_should_be_a_valid_video(response.videos.first)
  end
  
  def test_should_get_videos_for_multiword_metasearch_query
    response = @client.videos_by(:query => 'christina ricci')
    assert_equal 25, response.max_result_count
    # assert_equal 25, response.videos.size
  end
  
  def test_should_get_videos_for_one_tag
    # response = @client.videos_by(:tags => ['horse'])
  end
  
  private
  def test_should_be_a_valid_video(video)
    assert_not_nil video.title
    assert_equal "CHRISTINA RICCI NEARLY NAKED AND CHAINED FOR REALITY", video.title
  end
end
