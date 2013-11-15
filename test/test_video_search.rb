require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestVideoSearch < Test::Unit::TestCase
  def test_should_build_basic_query_url
    request = YouTubeIt::Request::VideoSearch.new(:query => "penguin")
    assert_equal "http://gdata.youtube.com/feeds/api/videos?q=penguin&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_multiword_metasearch_query_url
    request = YouTubeIt::Request::VideoSearch.new(:query => 'christina ricci')
    assert_equal "http://gdata.youtube.com/feeds/api/videos?q=christina+ricci&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_video_id_url
    request = YouTubeIt::Request::VideoSearch.new(:video_id => 'T7YazwP8GtY')
    assert_equal "http://gdata.youtube.com/feeds/api/videos/T7YazwP8GtY?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_one_tag_query_url
    request = YouTubeIt::Request::VideoSearch.new(:tags => ['panther'])
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/panther/?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_multiple_tags_query_url
    request = YouTubeIt::Request::VideoSearch.new(:tags => ['tiger', 'leopard'])
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/tiger/leopard/?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_one_category_query_url
    request = YouTubeIt::Request::VideoSearch.new(:categories => [:news])
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News/?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_multiple_categories_query_url
    request = YouTubeIt::Request::VideoSearch.new(:categories => [:news, :sports])
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News/Sports/?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_categories_and_tags_query_url
    request = YouTubeIt::Request::VideoSearch.new(:categories => [:news, :sports], :tags => ['soccer', 'football'])
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News/Sports/soccer/football/?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_categories_and_tags_url_with_max_results
    request = YouTubeIt::Request::VideoSearch.new(:categories => [:music], :tags => ['classic', 'rock'], :max_results => 2)
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/Music/classic/rock/?max-results=2&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_author_query_url
    request = YouTubeIt::Request::VideoSearch.new(:author => "davidguetta")
    assert_equal "http://gdata.youtube.com/feeds/api/videos?author=davidguetta&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_language_query_url
    request = YouTubeIt::Request::VideoSearch.new(:query => 'christina ricci', :lang => 'pt')
    assert_equal "http://gdata.youtube.com/feeds/api/videos?lr=pt&q=christina+ricci&v=#{YouTubeIt::API_VERSION}", request.url
  end

  # -- Standard Feeds --------------------------------------------------------------------------------

  def test_should_build_url_for_most_viewed
    request = YouTubeIt::Request::StandardSearch.new(:most_viewed)
    assert_equal "http://gdata.youtube.com/feeds/api/standardfeeds/most_viewed?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_url_for_top_rated_for_today
    request = YouTubeIt::Request::StandardSearch.new(:top_rated, :time => :today)
    assert_equal "http://gdata.youtube.com/feeds/api/standardfeeds/top_rated?time=today&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_url_for_most_viewed_offset_and_max_results_without_time
    request = YouTubeIt::Request::StandardSearch.new(:top_rated, :offset => 5, :max_results => 10)
    assert_equal "http://gdata.youtube.com/feeds/api/standardfeeds/top_rated?max-results=10&start-index=5&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_url_for_most_viewed_offset_and_max_results_with_time
    request = YouTubeIt::Request::StandardSearch.new(:top_rated, :offset => 5, :max_results => 10, :time => :today)
    assert_equal "http://gdata.youtube.com/feeds/api/standardfeeds/top_rated?max-results=10&start-index=5&time=today&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_url_for_most_viewed_region_ru_offset_and_max_results_with_time
    request = YouTubeIt::Request::StandardSearch.new(:top_rated, :offset => 5, :max_results => 10, :time => :today, :region => "RU")
    assert_equal "http://gdata.youtube.com/feeds/api/standardfeeds/RU/top_rated?max-results=10&start-index=5&time=today&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_url_for_most_viewed_region_ru_category_news_offset_and_max_results_with_time
    request = YouTubeIt::Request::StandardSearch.new(:top_rated, :offset => 5, :max_results => 10, :time => :today, :region => "RU", :category => "News")
    assert_equal "http://gdata.youtube.com/feeds/api/standardfeeds/RU/top_rated_News?max-results=10&start-index=5&time=today&v=#{YouTubeIt::API_VERSION}", request.url
  end


  def test_should_raise_exception_for_invalid_type
    assert_raise RuntimeError do
      request = YouTubeIt::Request::StandardSearch.new(:most_viewed_yo)
    end
  end

  # -- Complex Video Queries -------------------------------------------------------------------------

  def test_should_build_url_for_boolean_or_case_for_categories
    request = YouTubeIt::Request::VideoSearch.new(:categories => { :either => [:news, :sports] })
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News%7CSports/?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_url_for_boolean_or_and_exclude_case_for_categories
    request = YouTubeIt::Request::VideoSearch.new(:categories => { :either => [:news, :sports], :exclude => [:comedy] })
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News%7CSports/-Comedy/?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_url_for_exclude_case_for_tags
    request = YouTubeIt::Request::VideoSearch.new(:categories => { :either => [:news, :sports], :exclude => [:comedy] },
                                                 :tags => { :include => ['football'], :exclude => ['soccer'] })
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News%7CSports/-Comedy/football/-soccer/?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_url_for_either_case_for_tags
    request = YouTubeIt::Request::VideoSearch.new(:categories => { :either => [:news, :sports], :exclude => [:comedy] },
                                                 :tags => { :either => ['soccer', 'football', 'donkey'] })
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/News%7CSports/-Comedy/soccer%7Cfootball%7Cdonkey/?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_url_for_query_search_with_categories_excluded
    request = YouTubeIt::Request::VideoSearch.new(:query => 'bench press',
                                                 :categories => { :exclude => [:comedy, :entertainment] },
                                                 :max_results => 10)
    assert_equal "http://gdata.youtube.com/feeds/api/videos/-/-Comedy/-Entertainment/?max-results=10&q=bench+press&v=#{YouTubeIt::API_VERSION}", request.url
  end

  # -- User Queries ---------------------------------------------------------------------------------

  def test_should_build_url_for_videos_by_user
    request = YouTubeIt::Request::UserSearch.new(:user => 'liz')
    assert_equal "http://gdata.youtube.com/feeds/api/users/liz/uploads?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_url_for_videos_by_user_paginate_and_order
    request = YouTubeIt::Request::UserSearch.new(:user => 'liz', :offset => 20, :max_results => 10, :order_by => 'published')
    assert_equal "http://gdata.youtube.com/feeds/api/users/liz/uploads?max-results=10&orderby=published&start-index=20&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_url_for_favorite_videos_by_user
    request = YouTubeIt::Request::UserSearch.new(:favorites, :user => 'liz')
    assert_equal "http://gdata.youtube.com/feeds/api/users/liz/favorites?v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_url_for_favorite_videos_by_user_paginate
    request = YouTubeIt::Request::UserSearch.new(:favorites, :user => 'liz', :offset => 20, :max_results => 10)
    assert_equal "http://gdata.youtube.com/feeds/api/users/liz/favorites?max-results=10&start-index=20&v=#{YouTubeIt::API_VERSION}", request.url
  end
  
  # -- Queries with restrictions ---------------------------------------------------------------------------------
  
  def test_should_build_basic_query_url_with_restriction
    request = YouTubeIt::Request::VideoSearch.new(:query => "penguin", :restriction => "DE")
    assert_equal "http://gdata.youtube.com/feeds/api/videos?q=penguin&restriction=DE&v=#{YouTubeIt::API_VERSION}", request.url
  end

  # -- Params ---------------------------------------------------------------------------------
  def test_should_build_basic_query_url_with_duration
    request = YouTubeIt::Request::VideoSearch.new(:query => "penguin", :duration => "short")
    assert_equal "http://gdata.youtube.com/feeds/api/videos?duration=short&q=penguin&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_basic_query_url_with_time
    request = YouTubeIt::Request::VideoSearch.new(:query => "penguin", :time => "today")
    assert_equal "http://gdata.youtube.com/feeds/api/videos?q=penguin&time=today&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_basic_query_url_for_return_videos_with_caption
    request = YouTubeIt::Request::VideoSearch.new(:query => "penguin", :caption => "true")
    assert_equal "http://gdata.youtube.com/feeds/api/videos?caption=true&q=penguin&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_basic_query_url_for_return_hd_videos
    request = YouTubeIt::Request::VideoSearch.new(:query => "penguin", :hd => "true")
    assert_equal "http://gdata.youtube.com/feeds/api/videos?hd=true&q=penguin&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_basic_query_url_for_return_videos_partner
    request = YouTubeIt::Request::VideoSearch.new(:query => "penguin", :uploader => "partner")
    assert_equal "http://gdata.youtube.com/feeds/api/videos?q=penguin&uploader=partner&v=#{YouTubeIt::API_VERSION}", request.url
  end

  def test_should_build_basic_query_url_for_return_videos_by_region
    request = YouTubeIt::Request::VideoSearch.new(:query => "penguin", :region => "AR")
    assert_equal "http://gdata.youtube.com/feeds/api/videos?q=penguin&region=AR&v=#{YouTubeIt::API_VERSION}", request.url
  end
  def test_should_build_basic_query_url_for_return_videos_by_location
    request = YouTubeIt::Request::VideoSearch.new(:query => "penguin", :location => "37.42307,-122.08427")
    assert_equal "http://gdata.youtube.com/feeds/api/videos?location=37.42307%2C-122.08427&q=penguin&v=#{YouTubeIt::API_VERSION}", request.url
  end
end
