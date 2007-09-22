require 'rubygems'
require 'test/unit'
require 'pp'

require 'youtube_g'

class TestVideoSearch < Test::Unit::TestCase

  def test_should_build_basic_query_url
    request = YoutubeG::Request::VideoSearch.new(:query => "penguin")
    assert_equal "http://gdata.youtube.com/feeds/videos?vq=penguin", request.url
  end
  
  def test_should_build_multiword_metasearch_query_url
    request = YoutubeG::Request::VideoSearch.new(:query => 'christina ricci')
    assert_equal "http://gdata.youtube.com/feeds/videos?vq=christina+ricci", request.url
  end
  
  def test_should_build_one_tag_querl_url
    request = YoutubeG::Request::VideoSearch.new(:tags => ['panther'])
    assert_equal "http://gdata.youtube.com/feeds/videos/-/panther", request.url
  end
  
  def test_should_build_multiple_tags_query_url
    request = YoutubeG::Request::VideoSearch.new(:tags => ['tiger', 'leopard'])
    assert_equal "http://gdata.youtube.com/feeds/videos/-/tiger/leopard", request.url
  end
  
  def test_should_build_one_category_query_url
    request = YoutubeG::Request::VideoSearch.new(:categories => [:news])
    assert_equal "http://gdata.youtube.com/feeds/videos/-/News/", request.url
  end
  
  def test_should_build_multiple_categories_query_url
    request = YoutubeG::Request::VideoSearch.new(:categories => [:news, :sports])
    assert_equal "http://gdata.youtube.com/feeds/videos/-/News/Sports/", request.url
  end
  
  # def test_should_build_categories_and_tags_query_url
  #   request = YoutubeG::Request::VideoSearch.new(:categories => [:news, :sports], :tags => ['soccer', 'football'])
  #   assert_equal "http://gdata.youtube.com/feeds/videos/-/News/Sports/soccer/football", request.url
  # end
  
end
