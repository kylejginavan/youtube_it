require 'rubygems'
require 'test/unit'
require 'pp'

require 'youtube_g'

class TestVideoSearch < Test::Unit::TestCase
  def setup
    @client = YoutubeG::Client.new
  end

  def test_should_respond_to_a_basic_query
    response = @client.videos_by(:query => "christina ricci")

    assert_equal "http://gdata.youtube.com/feeds/videos", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 25, response.videos.length
    assert_equal 1, response.offset
    assert (response.total_result_count > 100)
    assert_instance_of Time, response.updated_at

    response.videos.each { |v| assert_valid_video v }
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

    def assert_valid_video (video)
      # check general attributes
      assert_instance_of YoutubeG::Model::Video, video
      # http://www.youtube.com/v/IHVaXG1thXM
      assert_valid_url video.content_url
      assert_instance_of Fixnum, video.duration
      assert (video.duration > 0)
      assert_instance_of YoutubeG::Model::Video::Format, video.format
      assert_match /^<div style=.*?<\/div>/m, video.html_content

      # validate keywords
      video.keywords.each { |kw| assert_instance_of(String, kw) }

      # http://www.youtube.com/watch?v=IHVaXG1thXM
      assert_valid_url video.player_url
      assert_instance_of Time, video.published_at

      # validate optionally-present rating
      if video.rating
        assert_instance_of YoutubeG::Model::Rating, video.rating
        assert_instance_of Float, video.rating.average
        assert_instance_of Fixnum, video.rating.max
        assert_instance_of Fixnum, video.rating.min
        assert_instance_of Fixnum, video.rating.rater_count
      end

      assert_not_nil video.title
      assert_instance_of String, video.title
      assert (video.title.length > 0)

      assert_instance_of Time, video.updated_at
      # http://gdata.youtube.com/feeds/videos/IHVaXG1thXM
      assert_valid_url video.video_id
      assert_instance_of Fixnum, video.view_count

      # validate author
      assert_instance_of YoutubeG::Model::Author, video.author
      assert_instance_of String, video.author.name
      assert (video.author.name.length > 0)
      assert_valid_url video.author.uri
      
      # validate categories
      video.categories.each do |cat|
        assert_instance_of YoutubeG::Model::Category, cat
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
