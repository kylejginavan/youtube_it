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
  
  def test_should_build_categories_and_tags_query_url
    request = YoutubeG::Request::VideoSearch.new(:categories => [:news, :sports], :tags => ['soccer', 'football'])
    assert_equal "http://gdata.youtube.com/feeds/videos/-/News/Sports/soccer/football", request.url
  end
  
  # -- Standard Feeds --------------------------------------------------------------------------------
  
  def test_should_build_url_for_most_viewed
    request = YoutubeG::Request::StandardSearch.new(:most_viewed)
    assert_equal "http://gdata.youtube.com/feeds/standardfeeds/most_viewed", request.url    
  end

  def test_should_raise_exception_for_invalid_type
    assert_raise RuntimeError do
      request = YoutubeG::Request::StandardSearch.new(:most_viewed_yo)
    end
  end

  def test_should_build_url_for_top_rated_for_today
    request = YoutubeG::Request::StandardSearch.new(:top_rated, :time => :today)
    assert_equal "http://gdata.youtube.com/feeds/standardfeeds/top_rated?time=today", request.url    
  end  
end
