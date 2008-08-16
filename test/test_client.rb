require 'rubygems'
require 'test/unit'
require 'pp'

require 'youtube_g'

class TestClient < Test::Unit::TestCase
  def setup
    @client = YouTubeG::Client.new
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

  # HTTP 403 Error
  # def test_should_get_favorite_videos_by_user
  #   response = @client.videos_by(:favorites, :user => 'liz')
  #   response.videos.each { |v| assert_valid_video v }
  # end
  
  def test_should_get_videos_for_query_search_with_categories_excluded
    video = @client.video_by("EkF4JD2rO3Q")
    assert_equal "<object width=\"425\" height=\"350\">\n  <param name=\"movie\" value=\"http://www.youtube.com/v/EkF4JD2rO3Q\"></param>\n  <param name=\"wmode\" value=\"transparent\"></param>\n  <embed src=\"http://www.youtube.com/v/EkF4JD2rO3Q\" type=\"application/x-shockwave-flash\" \n   wmode=\"transparent\" width=\"425\" height=\"350\"></embed>\n</object>\n", video.embed_html
    assert_valid_video video
  end

  def test_should_disable_debug_if_debug_is_set_to_false
    @client = YouTubeG::Client.new
    assert_nil @client.logger
  end
  
  def test_should_enable_logger_if_debug_is_true
    @client = YouTubeG::Client.new(true)
    assert_not_nil @client.logger
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
  
  private

    def assert_valid_video (video)
      # pp video

      # check general attributes
      assert_instance_of YouTubeG::Model::Video, video
      assert_instance_of Fixnum, video.duration
      assert(video.duration > 0)
      #assert_match(/^<div style=.*?<\/div>/m, video.html_content)
      assert_instance_of String, video.html_content

      # validate media content records
      video.media_content.each do |media_content|
        # http://www.youtube.com/v/IHVaXG1thXM
        assert_valid_url media_content.url
        assert(media_content.duration > 0)
        assert_instance_of YouTubeG::Model::Video::Format, media_content.format
        assert_instance_of String, media_content.mime_type
        assert_match(/^[^\/]+\/[^\/]+$/, media_content.mime_type)
      end

      default_content = video.default_media_content
      if default_content
        assert_instance_of YouTubeG::Model::Content, default_content
        assert default_content.is_default?
      end

      # validate keywords
      video.keywords.each { |kw| assert_instance_of(String, kw) }

      # http://www.youtube.com/watch?v=IHVaXG1thXM
      assert_valid_url video.player_url
      assert_instance_of Time, video.published_at

      # validate optionally-present rating
      if video.rating
        assert_instance_of YouTubeG::Model::Rating, video.rating
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

      # validate author
      assert_instance_of YouTubeG::Model::Author, video.author
      assert_instance_of String, video.author.name
      assert(video.author.name.length > 0)
      assert_valid_url video.author.uri
      
      # validate categories
      video.categories.each do |cat|
        assert_instance_of YouTubeG::Model::Category, cat
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
