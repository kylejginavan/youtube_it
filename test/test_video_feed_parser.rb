require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestVideoFeedParser < Test::Unit::TestCase

  # VIDEO ATTRIBUTES AFFECTED BY PARSING

  def test_should_display_unique_id_correctly_after_parsing
    with_video_response do |parser|
      video = parser.parse
      assert_equal "AbC123DeFgH", video.unique_id
    end
  end

  # PARSED VIDEO ATTRIBUTES
  def test_should_parse_duration_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal 356, video.duration
    end
  end

  def test_should_parse_widescreen_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal true, video.widescreen?
    end
  end

  def test_should_parse_noembed_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal false, video.noembed
    end
  end

  def test_should_parse_racy_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal false, video.racy
    end
  end

  def test_should_parse_video_id_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal "tag:youtube.com,2008:video:AbC123DeFgH", video.video_id
    end
  end

  def test_should_parse_published_at_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal Time.parse("Wed Dec 29 13:57:49 UTC 2010"), video.published_at
    end
  end

  def test_should_parse_updated_at_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal Time.parse("Wed Feb 23 13:54:16 UTC 2011"), video.updated_at
    end
  end
  
  def test_should_parse_categories_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal "Test", video.categories.first.label
      assert_equal "Test", video.categories.first.term
    end
  end

  def test_should_parse_keywords_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal ["test"], video.keywords
    end
  end

  def test_should_parse_description_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal "Youtube Test Video", video.description
    end
  end

  def test_should_parse_title_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal "YouTube Test Video", video.title
    end
  end

  def test_should_parse_html_content_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal nil, video.html_content
    end
  end

  def test_should_parse_thumbnails_correctly
    with_video_response do |parser|
      video = parser.parse
      thumbnail = video.thumbnails.first
      assert_equal 90, thumbnail.height
      assert_equal "00:02:58", thumbnail.time
      assert_equal "http://i.ytimg.com/vi/AbC123DeFgH/default.jpg", thumbnail.url
      assert_equal 120, thumbnail.width
    end
  end

  def test_should_parse_player_url_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal "http://www.youtube.com/watch?v=AbC123DeFgH&feature=youtube_gdata_player", video.player_url
    end
  end

  def test_should_parse_view_count_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal 240000, video.view_count
    end
  end

  def test_should_parse_favorite_count_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal 200, video.favorite_count
    end
  end

  # RATING

  def test_should_parse_average_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal 4.305027, video.rating.average
    end
  end

  def test_should_parse_max_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal 5, video.rating.max
    end
  end

  def test_should_parse_min_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal 1, video.rating.min
    end
  end

  def test_should_parse_rater_count_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal 2049, video.rating.rater_count
    end
  end

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
  
  # TOD: GEODATA

  def test_should_parse_where_geodata_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal nil, video.where
    end
  end
  
  def test_should_parse_position_geodata_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal nil, video.position
    end
  end
  
  def test_should_parse_latitude_geodata_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal nil, video.latitude
    end
  end
  
  def test_should_parse_longitude_geodata_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal nil, video.longitude
    end
  end

  # AUTHOR

  def test_should_parse_author_name_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal "Test user", video.author.name
    end
  end

  def test_should_parse_author_uri_correctly
    with_video_response do |parser|
      video = parser.parse
      assert_equal "http://gdata.youtube.com/feeds/api/users/test_user", video.author.uri
    end
  end

  # MEDIA CONTENT

  def test_should_parse_if_media_content_is_default_content_correctly
    with_video_response do |parser|
      video = parser.parse
      content = video.media_content.first
      assert_equal true, content.default
    end
  end

  def test_should_parse_duration_of_media_contents_correctly
    with_video_response do |parser|
      video = parser.parse
      content = video.media_content.first
      assert_equal 356, content.duration
    end
  end
  
  def test_should_parse_mime_type_of_media_content_correctly
    with_video_response do |parser|
      video = parser.parse
      content = video.media_content.first
      assert_equal "application/x-shockwave-flash", content.mime_type
    end
  end

  def test_should_parse_url_of_media_content_correctly
    with_video_response do |parser|
      video = parser.parse
      content = video.media_content.first
      assert_equal "http://www.youtube.com/v/AbC123DeFgH?f=videos&app=youtube_gdata", content.url
    end
  end

  def with_video_response &block
    File.open(File.dirname(__FILE__) + '/files/youtube_video_response.xml') do |xml|
      parser = YouTubeIt::Parser::VideoFeedParser.new xml.read
      yield parser
    end
  end
end
