require File.dirname(__FILE__) + '/helper'

class TestClient < Test::Unit::TestCase

  OPTIONS = {:title => "test title",
             :description => "test description",
             :category => 'People',
             :keywords => %w[test]}
  ACCOUNT = {:user => "tubeit20101", :passwd => "youtube_it", :dev_key => "AI39si411VBmO4Im9l0rfRsORXDI6F5AX5NlTIA4uHSWqa-Cgf-jUQG-6osUBB3PTLawLHlkKXPLr3B0pNcGU9wkNd11gIgdPg" }
  RAILS_ENV = "test"

  def setup
    @client = YouTubeIt::Client.new(ACCOUNT[:user], ACCOUNT[:passwd] , ACCOUNT[:dev_key])
  end

  def test_should_respond_to_a_basic_query
    response = @client.videos_by(:query => "penguin")

    assert_equal "http://gdata.youtube.com/feeds/api/videos", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 25, response.videos.length
    assert_equal 1, response.offset
    assert(response.total_result_count > 100)
    assert_instance_of Time, response.updated_at

    response.videos.each { |v| assert_valid_video v }
  end

    def test_should_respond_to_a_basic_query_with_offset_and_max_results
    response = @client.videos_by(:query => "penguin", :offset => 15, :max_results => 30)

    assert_equal "http://gdata.youtube.com/feeds/api/videos", response.feed_id
    assert_equal 30, response.max_result_count
    assert_equal 30, response.videos.length
    assert_equal 15, response.offset
    assert(response.total_result_count > 100)
    assert_instance_of Time, response.updated_at

    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_respond_to_a_basic_query_with_paging
    response = @client.videos_by(:query => "penguin")
    assert_equal "http://gdata.youtube.com/feeds/api/videos", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 1, response.offset

    response = @client.videos_by(:query => "penguin", :page => 2)
    assert_equal "http://gdata.youtube.com/feeds/api/videos", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 26, response.offset

    response2 = @client.videos_by(:query => "penguin", :page => 3)
    assert_equal "http://gdata.youtube.com/feeds/api/videos", response2.feed_id
    assert_equal 25, response2.max_result_count
    assert_equal 51, response2.offset
  end

  def test_should_get_videos_for_multiword_metasearch_query
    response = @client.videos_by(:query => 'christina ricci')

    assert_equal "http://gdata.youtube.com/feeds/api/videos", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 25, response.videos.length
    assert_equal 1, response.offset
    assert(response.total_result_count > 100)
    assert_instance_of Time, response.updated_at

    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_handle_video_not_yet_viewed
    response = @client.videos_by(:query => "YnqHZDh_t2Q")

    assert_equal 1, response.videos.length
    response.videos.each { |v| assert_valid_video v }
  end

  # TODO: this doesn't work because the returned feed is in an unknown format
  # def test_should_get_video_for_search_by_video_id
  #   response = @client.videos_by(:video_id => "T7YazwP8GtY")
  #   response.videos.each { |v| assert_valid_video v }
  # end

  def test_should_get_videos_for_one_tag
    response = @client.videos_by(:tags => ['panther'])
    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_get_videos_for_multiple_tags
    response = @client.videos_by(:tags => ['tiger', 'leopard'])
    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_get_videos_for_one_category
    response = @client.videos_by(:categories => [:news])
    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_get_videos_for_multiple_categories
    response = @client.videos_by(:categories => [:news, :sports])
    response.videos.each { |v| assert_valid_video v }
  end

  # TODO: Need to do more specific checking in these tests
  # Currently, if a URL is valid, and videos are found, the test passes regardless of search criteria
  def test_should_get_videos_for_categories_and_tags
    response = @client.videos_by(:categories => [:news, :sports], :tags => ['soccer', 'football'])
    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_get_most_viewed_videos
    response = @client.videos_by(:most_viewed)
    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_get_top_rated_videos_for_today
    response = @client.videos_by(:top_rated, :time => :today)
    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_get_videos_for_categories_and_tags_with_category_boolean_operators
    response = @client.videos_by(:categories => { :either => [:news, :sports], :exclude => [:comedy] },
                                 :tags => { :include => ['football'], :exclude => ['soccer'] })
    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_get_videos_for_categories_and_tags_with_tag_boolean_operators
    response = @client.videos_by(:categories => { :either => [:news, :sports], :exclude => [:comedy] },
                                 :tags => { :either => ['football', 'soccer', 'polo'] })
    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_get_videos_by_user
    response = @client.videos_by(:user => 'liz')
    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_get_videos_by_user_with_pagination_and_ordering
    response = @client.videos_by(:user => 'liz', :page => 2, :per_page => '2', :order_by => 'published')
    response.videos.each { |v| assert_valid_video v }
    assert_equal 3, response.offset
    assert_equal 2, response.max_result_count
  end

  def test_should_get_favorite_videos_by_user
    response = @client.videos_by(:favorites, :user => 'drnicwilliams')
    assert_equal "http://gdata.youtube.com/feeds/api/users/drnicwilliams/favorites", response.feed_id
    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_get_videos_for_query_search_with_categories_excluded
    video = @client.video_by("EkF4JD2rO3Q")
    assert_equal "<object width=\"425\" height=\"350\">\n  <param name=\"movie\" value=\"http://www.youtube.com/v/EkF4JD2rO3Q&feature=youtube_gdata\"></param>\n  <param name=\"wmode\" value=\"transparent\"></param>\n  <embed src=\"http://www.youtube.com/v/EkF4JD2rO3Q&feature=youtube_gdata\" type=\"application/x-shockwave-flash\" \n   wmode=\"transparent\" width=\"425\" height=\"350\"></embed>\n</object>\n", video.embed_html
    assert_valid_video video
  end

  def test_should_get_video_from_user
    video = @client.video_by_user("chebyte","FQK1URcxmb4")
    assert_equal "<object width=\"425\" height=\"350\">\n  <param name=\"movie\" value=\"http://www.youtube.com/v/FQK1URcxmb4&feature=youtube_gdata\"></param>\n  <param name=\"wmode\" value=\"transparent\"></param>\n  <embed src=\"http://www.youtube.com/v/FQK1URcxmb4&feature=youtube_gdata\" type=\"application/x-shockwave-flash\" \n   wmode=\"transparent\" width=\"425\" height=\"350\"></embed>\n</object>\n", video.embed_html
    assert_valid_video video
  end


  def test_should_always_return_a_logger
    @client = YouTubeIt::Client.new
    assert_not_nil @client.logger
  end

  def test_should_not_bail_if_debug_is_true
    assert_nothing_raised { YouTubeIt::Client.new(true) }
  end

  def test_should_determine_if_nonembeddable_video_is_embeddable
    response = @client.videos_by(:query => "avril lavigne girlfriend")

    video = response.videos.first
    assert !video.embeddable?
  end

  def test_should_determine_if_embeddable_video_is_embeddable
    response = @client.videos_by(:query => "strongbad")

    video = response.videos.first
    assert video.embeddable?
  end

  def test_should_retrieve_video_by_id
    video = @client.video_by("http://gdata.youtube.com/feeds/videos/EkF4JD2rO3Q")
    assert_valid_video video

    video = @client.video_by("EkF4JD2rO3Q")
    assert_valid_video video
  end

  def test_return_upload_info_for_upload_from_browser
    response = @client.upload_token(OPTIONS)
    assert response.kind_of?(Hash)
    assert response.size, 2
    response.each do |k,v|
      assert v
    end
  end

  def test_should_upload_a_video
    video_id  = @client.video_upload(File.open("test/test.mov"), OPTIONS)
    video     = @client.video_by_user(ACCOUNT[:user], video_id)
    assert_valid_video video
    @client.video_delete(video_id)
  end

  def test_should_update_a_video
    OPTIONS[:title] = "title changed"
    video_id  = @client.video_upload(File.open("test/test.mov"), OPTIONS)
    @client.video_update(video_id, OPTIONS)
    video     = @client.video_by_user(ACCOUNT[:user], video_id)
    assert_valid_video video
    assert video.title == "title changed"
    @client.video_delete(video_id)
  end

  def test_should_delete_video
    video_id  = @client.video_upload(File.open("test/test.mov"), OPTIONS)
    video     = @client.video_by_user(ACCOUNT[:user], video_id)
    assert_valid_video video
    assert @client.video_delete(video_id)
  end

  private

    def assert_valid_video (video)
      # check general attributes
      assert_instance_of YouTubeIt::Model::Video, video
      assert_instance_of Fixnum, video.duration
      assert_instance_of String, video.html_content if video.html_content

      # validate media content records
      video.media_content.each do |media_content|
        assert_valid_url media_content.url
        assert_instance_of YouTubeIt::Model::Video::Format, media_content.format
        assert_instance_of String, media_content.mime_type
        assert_match(/^[^\/]+\/[^\/]+$/, media_content.mime_type)
      end

      default_content = video.default_media_content
      if default_content
        assert_instance_of YouTubeIt::Model::Content, default_content
        assert default_content.is_default?
      end

      # validate keywords
      video.keywords.each { |kw| assert_instance_of(String, kw) }

      # http://www.youtube.com/watch?v=IHVaXG1thXM
      assert_valid_url video.player_url
      assert_instance_of Time, video.published_at

      # validate optionally-present rating
      if video.rating
        assert_instance_of YouTubeIt::Model::Rating, video.rating
        assert_instance_of Float, video.rating.average
        assert_instance_of Fixnum, video.rating.max
        assert_instance_of Fixnum, video.rating.min
        assert_instance_of Fixnum, video.rating.rater_count
      end

      # validate thumbnails
      assert(video.thumbnails.size > 0)

      assert_not_nil video.title
      assert_instance_of String, video.title
      assert(video.title.length > 0)

      assert_instance_of Time, video.updated_at
      # http://gdata.youtube.com/feeds/videos/IHVaXG1thXM
      assert_valid_url video.video_id
      assert_instance_of Fixnum, video.view_count
      assert_instance_of Fixnum, video.favorite_count

      # validate author
      assert_instance_of YouTubeIt::Model::Author, video.author
      assert_instance_of String, video.author.name
      assert(video.author.name.length > 0)
      assert_valid_url video.author.uri

      # validate categories
      video.categories.each do |cat|
        assert_instance_of YouTubeIt::Model::Category, cat
        assert_instance_of String, cat.label
        assert_instance_of String, cat.term
      end
    end

    def assert_valid_url (url)
      URI::parse(url)
      return true
    rescue
      return false
    end
end

