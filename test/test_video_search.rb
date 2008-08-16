require 'rubygems'
require 'test/unit'
require 'pp'

require 'youtube_g'

class TestVideoSearch < Test::Unit::TestCase

  def test_should_build_basic_query_url
    request = YouTubeG::Request::VideoSearch.new(:query => "penguin")
    assert_equal "http://gdata.youtube.com/feeds/api/videos?vq=penguin", request.url
  end
  
  def test_should_build_multiword_metasearch_query_url
    request = YouTubeG::Request::VideoSearch.new(:query => 'christina ricci')
    assert_equal "http://gdata.youtube.com/feeds/api/videos?vq=christina+ricci", request.url
  end
  
  def test_should_build_video_id_url
    request = YouTubeG::Request::VideoSearch.new(:video_id => 'T7YazwP8GtY')
    assert_equal "http://gdata.youtube.com/feeds/api/videos/T7YazwP8GtY", request.url
  end

  def test_should_build_one_tag_querl_url
    request = YouTubeG::Request::VideoSearch.new(:tags => ['panther'])
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/panther/", request.url
  end
  
  def test_should_build_multiple_tags_query_url
    request = YouTubeG::Request::VideoSearch.new(:tags => ['tiger', 'leopard'])
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/tiger/leopard/", request.url
  end
  
  def test_should_build_one_category_query_url
    request = YouTubeG::Request::VideoSearch.new(:categories => [:news])
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News/", request.url
  end
  
  def test_should_build_multiple_categories_query_url
    request = YouTubeG::Request::VideoSearch.new(:categories => [:news, :sports])
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News/Sports/", request.url
  end
  
  def test_should_build_categories_and_tags_query_url
    request = YouTubeG::Request::VideoSearch.new(:categories => [:news, :sports], :tags => ['soccer', 'football'])
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News/Sports/soccer/football/", request.url
  end
  
  def test_should_build_categories_and_tags_url_with_max_results
    request = YouTubeG::Request::VideoSearch.new(:categories => [:music], :tags => ['classic', 'rock'], :max_results => 2)
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/Music/classic/rock/?max-results=2", request.url
  end
  
  def test_should_build_author_query_url
    request = YouTubeG::Request::VideoSearch.new(:author => "davidguetta")
    assert_equal "http://gdata.youtube.com/feeds/api/videos?author=davidguetta", request.url
  end
  # -- Standard Feeds --------------------------------------------------------------------------------
  
  def test_should_build_url_for_most_viewed
    request = YouTubeG::Request::StandardSearch.new(:most_viewed)
    assert_equal "http://gdata.youtube.com/feeds/api/standardfeeds/most_viewed", request.url    
  end
  
  def test_should_build_url_for_top_rated_for_today
    request = YouTubeG::Request::StandardSearch.new(:top_rated, :time => :today)
    assert_equal "http://gdata.youtube.com/feeds/api/standardfeeds/top_rated?time=today", request.url    
  end  
  
  def test_should_build_url_for_most_viewed_offset_and_max_results_without_time
    request = YouTubeG::Request::StandardSearch.new(:top_rated, :offset => 5, :max_results => 10)
    assert_equal "http://gdata.youtube.com/feeds/api/standardfeeds/top_rated?max-results=10&start-index=5", request.url   
  end
  
  def test_should_build_url_for_most_viewed_offset_and_max_results_with_time
    request = YouTubeG::Request::StandardSearch.new(:top_rated, :offset => 5, :max_results => 10, :time => :today)
    assert_equal "http://gdata.youtube.com/feeds/api/standardfeeds/top_rated?max-results=10&start-index=5&time=today", request.url   
  end

  def test_should_raise_exception_for_invalid_type
    assert_raise RuntimeError do
      request = YouTubeG::Request::StandardSearch.new(:most_viewed_yo)
    end
  end
  
  # -- Complex Video Queries -------------------------------------------------------------------------
  
  def test_should_build_url_for_boolean_or_case_for_categories
    request = YouTubeG::Request::VideoSearch.new(:categories => { :either => [:news, :sports] })
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News%7CSports/", request.url
  end

  def test_should_build_url_for_boolean_or_and_exclude_case_for_categories
    request = YouTubeG::Request::VideoSearch.new(:categories => { :either => [:news, :sports], :exclude => [:comedy] })
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News%7CSports/-Comedy/", request.url
  end

  def test_should_build_url_for_exclude_case_for_tags
    request = YouTubeG::Request::VideoSearch.new(:categories => { :either => [:news, :sports], :exclude => [:comedy] },
                                                 :tags => { :include => ['football'], :exclude => ['soccer'] })
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News%7CSports/-Comedy/football/-soccer/", request.url
  end

  def test_should_build_url_for_either_case_for_tags
    request = YouTubeG::Request::VideoSearch.new(:categories => { :either => [:news, :sports], :exclude => [:comedy] },
                                                 :tags => { :either => ['soccer', 'football', 'donkey'] })
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News%7CSports/-Comedy/soccer%7Cfootball%7Cdonkey/", request.url
  end
  
  def test_should_build_url_for_query_search_with_categories_excluded
    request = YouTubeG::Request::VideoSearch.new(:query => 'bench press', 
                                                 :categories => { :exclude => [:comedy, :entertainment] },
                                                 :max_results => 10)
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/-Comedy/-Entertainment/?max-results=10&vq=bench+press", request.url
  end
  
  # -- User Queries ---------------------------------------------------------------------------------
  
  def test_should_build_url_for_videos_by_user
    request = YouTubeG::Request::UserSearch.new(:user => 'liz')
    assert_equal "http://gdata.youtube.com/feeds/api/users/liz/uploads", request.url
  end
  
  def test_should_build_url_for_videos_by_user_paginate_and_order
    request = YouTubeG::Request::UserSearch.new(:user => 'liz', :offset => 20, :max_results => 10, :order_by => 'published')
    assert_equal "http://gdata.youtube.com/feeds/api/users/liz/uploads?max-results=10&orderby=published&start-index=20", request.url
  end

  def test_should_build_url_for_favorite_videos_by_user
    request = YouTubeG::Request::UserSearch.new(:favorites, :user => 'liz')
    assert_equal "http://gdata.youtube.com/feeds/api/users/liz/favorites", request.url
  end

  def test_should_build_url_for_favorite_videos_by_user_paginate
    request = YouTubeG::Request::UserSearch.new(:favorites, :user => 'liz', :offset => 20, :max_results => 10)
    assert_equal "http://gdata.youtube.com/feeds/api/users/liz/favorites?max-results=10&start-index=20", request.url
  end
end
