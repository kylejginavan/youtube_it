#encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestClient < Test::Unit::TestCase

  OPTIONS = {
    :title       => "test title",
    :description => "test description",
    :category    => 'People',
    :keywords    => %w[test]
  }
  ACCOUNT = {
    :username => "tubeit20101",
    :password => "youtube_it",
    :dev_key  => "AI39si411VBmO4Im9l0rfRsORXDI6F5AX5NlTIA4uHSWqa-Cgf-jUQG-6osUBB3PTLawLHlkKXPLr3B0pNcGU9wkNd11gIgdPg"
  }

  def setup
    # clientlogin
    @client = YouTubeIt::Client.new(ACCOUNT)

    # authsub
    # @client = YouTubeIt::AuthSubClient.new(:token => "1/vqYlJytmn4eWRjJnORHT94mENNfZzZsLutMOrvvygB4" , :dev_key => ACCOUNT[:dev_key])
  end

  def test_should_respond_to_a_basic_query
    VCR.use_cassette("penguin") do
      response = @client.videos_by(:query => "penguin")

      assert_equal "tag:youtube.com,2008:videos", response.feed_id
      assert_equal 25, response.max_result_count
      assert_equal 25, response.videos.length
      assert_equal 1, response.offset
      assert(response.total_result_count > 100)
      assert_instance_of Time, response.updated_at

      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_respond_to_a_basic_query_with_offset_and_max_results
    VCR.use_cassette("penguin,offset:15,max:30") do
      response = @client.videos_by(:query => "penguin", :offset => 15, :max_results => 30)

      assert_equal "tag:youtube.com,2008:videos", response.feed_id
      assert_equal 30, response.max_result_count
      assert_equal 30, response.videos.length
      assert_equal 15, response.offset
      assert(response.total_result_count > 100)
      assert_instance_of Time, response.updated_at

      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_respond_to_a_basic_query_with_paging
    VCR.use_cassette("penguin") do
      response = @client.videos_by(:query => "penguin")
      assert_equal "tag:youtube.com,2008:videos", response.feed_id
      assert_equal 25, response.max_result_count
      assert_equal 1, response.offset
    end

    VCR.use_cassette("penguin,page:2") do
      response = @client.videos_by(:query => "penguin", :page => 2)
      assert_equal "tag:youtube.com,2008:videos", response.feed_id
      assert_equal 25, response.max_result_count
      assert_equal 26, response.offset
    end

    VCR.use_cassette("penguin,page:3") do
      response2 = @client.videos_by(:query => "penguin", :page => 3)
      assert_equal "tag:youtube.com,2008:videos", response2.feed_id
      assert_equal 25, response2.max_result_count
      assert_equal 51, response2.offset
    end
  end

  def test_should_get_videos_for_multiword_metasearch_query
    VCR.use_cassette("christina ricci") do
      response = @client.videos_by(:query => 'christina ricci')

      assert_equal "tag:youtube.com,2008:videos", response.feed_id
      assert_equal 25, response.max_result_count
      assert_equal 25, response.videos.length
      assert_equal 1, response.offset
      assert(response.total_result_count > 100)
      assert_instance_of Time, response.updated_at

      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_handle_video_not_yet_viewed
    VCR.use_cassette("CE62FSEoY28") do
      response = @client.videos_by(:query => "CE62FSEoY28")

      assert_equal 1, response.videos.length
      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_get_videos_for_one_tag
    VCR.use_cassette("tags:panther") do
      response = @client.videos_by(:tags => ['panther'])
      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_get_videos_for_multiple_tags
    VCR.use_cassette("tags:tiger,leopard") do
      response = @client.videos_by(:tags => ['tiger', 'leopard'])
      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_get_videos_for_one_category
    VCR.use_cassette("categories:news") do
      response = @client.videos_by(:categories => [:news])
      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_get_videos_for_multiple_categories
    VCR.use_cassette("categories:news,sports") do
      response = @client.videos_by(:categories => [:news, :sports])
      response.videos.each { |v| assert_valid_video v }
    end
  end

  # TODO: Need to do more specific checking in these tests
  # Currently, if a URL is valid, and videos are found, the test passes regardless of search criteria
  def test_should_get_videos_for_categories_and_tags
    VCR.use_cassette("categories:news,sports;tags:soccer,football") do
      response = @client.videos_by(:categories => [:news, :sports], :tags => ['soccer', 'football'])
      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_get_most_viewed_videos
    VCR.use_cassette(":most_viewed") do
      response = @client.videos_by(:most_viewed)
      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_get_top_rated_videos_for_today
    VCR.use_cassette(":top_rated;time:today") do
      response = @client.videos_by(:top_rated, :time => :today)
      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_get_videos_for_categories_and_tags_with_category_boolean_operators
    VCR.use_cassette("categories:news|sports-comedy;tags:football-soccer") do
      response = @client.videos_by(:categories => { :either => [:news, :sports], :exclude => [:comedy] },
      :tags => { :include => ['football'], :exclude => ['soccer'] })
      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_get_videos_for_categories_and_tags_with_tag_boolean_operators
    VCR.use_cassette("categories:news|sports-comedy;tags:football|soccer|polo") do
      response = @client.videos_by(:categories => { :either => [:news, :sports], :exclude => [:comedy] },
      :tags => { :either => ['football', 'soccer', 'polo'] })
      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_get_videos_by_user
    VCR.use_cassette("user:liz") do
      response = @client.videos_by(:user => 'liz')
      response.videos.each { |v| assert_valid_video v }
    end
  end

  def test_should_get_videos_by_user_with_pagination_and_ordering
    VCR.use_cassette("user:liz,page:2,per_page:2,order:published") do
      response = @client.videos_by(:user => 'liz', :page => 2, :per_page => '2', :order_by => 'published')
      response.videos.each { |v| assert_valid_video v }
      assert_equal 3, response.offset
      assert_equal 2, response.max_result_count
    end
  end


  def test_should_get_favorite_videos_by_user
    VCR.use_cassette(":favorites,user:drnicwilliams") do
      response = @client.videos_by(:favorites, :user => 'drnicwilliams')
      assert_equal "tag:youtube.com,2008:user:drnicwilliams:favorites", response.feed_id
      assert_valid_video response.videos.first
    end
  end

  def test_should_get_videos_for_query_search_with_categories_excluded
    VCR.use_cassette("EkF4JD2rO3Q") do
      video = @client.video_by("EkF4JD2rO3Q")
      assert_equal "<object width=\"425\" height=\"350\">\n  <param name=\"movie\" value=\"http://www.youtube.com/v/EkF4JD2rO3Q&feature=youtube_gdata_player\"></param>\n  <param name=\"wmode\" value=\"transparent\"></param>\n  <embed src=\"http://www.youtube.com/v/EkF4JD2rO3Q&feature=youtube_gdata_player\" type=\"application/x-shockwave-flash\"\n   wmode=\"transparent\" width=\"425\" height=\"350\"></embed>\n</object>\n", video.embed_html
      assert_valid_video video
    end
  end

  def test_should_get_video_from_user
    VCR.use_cassette("user:chebyte,FQK1URcxmb4") do
      video = @client.video_by_user("chebyte","FQK1URcxmb4")
      assert_equal "<object width=\"425\" height=\"350\">\n  <param name=\"movie\" value=\"http://www.youtube.com/v/FQK1URcxmb4&feature=youtube_gdata_player\"></param>\n  <param name=\"wmode\" value=\"transparent\"></param>\n  <embed src=\"http://www.youtube.com/v/FQK1URcxmb4&feature=youtube_gdata_player\" type=\"application/x-shockwave-flash\"\n   wmode=\"transparent\" width=\"425\" height=\"350\"></embed>\n</object>\n", video.embed_html
      assert_valid_video video
    end
  end

  def test_should_always_return_a_logger
    @client = YouTubeIt::Client.new
    assert_not_nil @client.logger
  end

  def test_should_not_bail_if_debug_is_true
    assert_nothing_raised { YouTubeIt::Client.new(:debug => true) }
  end

  def test_should_determine_if_embeddable_video_is_embeddable
    VCR.use_cassette("strongbad") do
      response = @client.videos_by(:query => "strongbad")

      video = response.videos.first
      assert video.embeddable?
    end
  end

  def test_should_retrieve_video_by_id
    VCR.use_cassette("url:EkF4JD2rO3Q") do
      video = @client.video_by("http://gdata.youtube.com/feeds/videos/EkF4JD2rO3Q")
      assert_valid_video video
    end

    VCR.use_cassette("EkF4JD2rO3Q") do
      video = @client.video_by("EkF4JD2rO3Q")
      assert_valid_video video
    end
  end

  def test_return_upload_info_for_upload_from_browser
    VCR.use_cassette("upload_token") do
      response = @client.upload_token(OPTIONS)
      assert response.kind_of?(Hash)
      assert_equal response.size, 2
      response.each do |k,v|
        assert v
      end
    end
  end

  def test_should_upload_a_video
    VCR.use_cassette("upload") do
      video  = @client.video_upload(File.open("test/test.mov"), OPTIONS)
      assert_valid_video video
      @client.video_delete(video.unique_id)
    end
  end

  def test_should_update_a_video
    VCR.use_cassette("upload_and_update_title_changed") do
      options = OPTIONS.merge(:title => "title changed")
      video  = @client.video_upload(File.open("test/test.mov"), options)
      updated_video  = @client.video_update(video.unique_id, options)
      assert updated_video.title == "title changed"
      @client.video_delete(video.unique_id)
    end
  end

  def test_should_denied_comments
    VCR.use_cassette("upload_and_find_denied_comments") do
      video = @client.video_upload(File.open("test/test.mov"), OPTIONS.merge(:comment => "denied"))
      assert_valid_video video
      doc = open("http://www.youtube.com/watch?v=#{video.unique_id}").read
      assert "Adding comments has been disabled for this video.", doc.match("Adding comments has been disabled for this video.")[0]
      @client.video_delete(video.unique_id)
    end
  end

  def test_should_denied_rate
    VCR.use_cassette("upload_and_find_denied_ratings") do
      video  = @client.video_upload(File.open("test/test.mov"), OPTIONS.merge(:rate => "denied"))
      assert_valid_video video
      doc = open("http://www.youtube.com/watch?v=#{video.unique_id}").read
      assert "Ratings have been disabled for this video.", doc.match("Ratings have been disabled for this video.")[0]
      @client.video_delete(video.unique_id)
    end
  end

  def test_should_denied_embed
    VCR.use_cassette("upload_noembed") do
      video = @client.video_upload(File.open("test/test.mov"), OPTIONS.merge(:embed => "denied"))
      assert video.noembed
      @client.video_delete(video.unique_id)
    end
  end

  def test_should_add_new_comment
    VCR.use_cassette("upload_and_comment") do
      video = @client.video_upload(File.open("test/test.mov"), OPTIONS)
      @client.add_comment(video.unique_id, "test comment")
      comment = @client.comments(video.unique_id).first.content
      assert comment, "test comment"
      @client.video_delete(video.unique_id)
    end
  end

  def test_should_add_and_delete_video_from_playlist
    VCR.use_cassette("add_and_delete_from_playlist") do
      playlist = @client.add_playlist(:title => "youtube_it test!", :description => "test playlist")
      video = @client.add_video_to_playlist(playlist.playlist_id,"CE62FSEoY28")
      assert_equal video[:code].to_i, 201
      assert_equal "CE62FSEoY28", playlist.videos.last.unique_id
      assert @client.delete_video_from_playlist(playlist.playlist_id, video[:playlist_entry_id])
      assert @client.delete_playlist(playlist.playlist_id)
    end
  end

  def test_should_add_and_delete_new_playlist
    VCR.use_cassette("add_and_delete_new_playlist") do
      result = @client.add_playlist(:title => "youtube_it test4!", :description => "test playlist")
      assert result.title, "youtube_it test!"
      sleep 4
      assert @client.delete_playlist(result.playlist_id)
    end
  end

  def test_should_update_playlist
    VCR.use_cassette("update_playlist") do
      playlist = @client.add_playlist(:title => "youtube_it test!", :description => "test playlist")
      sleep 30
      playlist_updated = @client.update_playlist(playlist.playlist_id, :title => "title changed")
      assert_equal playlist_updated.title, "title changed"
      assert @client.delete_playlist(playlist.playlist_id)
    end
  end

  def test_should_list_playlist_for_user
    VCR.use_cassette("find_chebyte_playlists") do
      result = @client.playlists('chebyte')
      assert result.last.title, "rock"
    end
  end

  def test_should_determine_if_widescreen_video_is_widescreen
    VCR.use_cassette("QqQVll-MP3I") do
      widescreen_id = "QqQVll-MP3I"
      video = @client.video_by(widescreen_id)
      assert video.widescreen?
    end
  end

  def test_get_current_user
    VCR.use_cassette("current_user") do
      assert_equal @client.current_user, "tubeit20101"
    end
  end

  def test_should_get_my_videos
    VCR.use_cassette("my_videos") do
      video  = @client.video_upload(File.open("test/test.mov"), OPTIONS)
      assert_valid_video video
      result = @client.my_videos
      assert_equal result.videos.first.unique_id, video.unique_id
      @client.video_delete(video.unique_id)
    end
  end

  def test_should_get_my_video
    VCR.use_cassette("my_video") do
      video  = @client.video_upload(File.open("test/test.mov"), OPTIONS)
      assert_valid_video video
      result = @client.my_video(video.unique_id)
      assert_equal result.unique_id, video.unique_id
      @client.video_delete(video.unique_id)
    end
  end

  def test_should_add_like_and_dislike_to_video
    VCR.use_cassette("like_and_dislike_CE62FSEoY28") do
      r = @client.like_video("CE62FSEoY28")
      assert_equal 201, r[:code]
      r = @client.dislike_video("CE62FSEoY28")
      assert_equal 201, r[:code]
    end
  end

  def test_should_subscribe_and_unsubscribe_to_channel
    VCR.use_cassette("subscribe_TheWoWArthas") do
      r = @client.subscribe_channel("TheWoWArthas")
      assert_equal 201, r[:code]
      assert_equal 1, @client.subscriptions.count
      assert_equal "Videos published by: TheWoWArthas", @client.subscriptions.first.title
      r = @client.unsubscribe_channel(@client.subscriptions.first.id)
      assert_equal 200, r[:code]
    end
  end

  def test_should_get_profile
    VCR.use_cassette("profile") do
      profile = @client.profile
      assert_equal profile.username, "tubeit20101"
    end
  end

  def test_should_add_and_delete_video_to_favorite
    VCR.use_cassette("add_and_delete_j5raG94IGCc_to_favorite") do
      video_id ="j5raG94IGCc"
      result = @client.add_favorite(video_id)
      assert_equal result[:code], 201
      sleep 4
      assert @client.delete_favorite(video_id)
    end
  end

  def test_esc
    result = YouTubeIt.esc("спят усталые игрушки")
    assert result, "спят+усталые+игрушки"
  end

  def test_unicode_query
    VCR.use_cassette("unicode") do
      videos = @client.videos_by(:query => 'спят усталые игрушки').videos
      assert videos.map(&:unique_id).include?("w-7BT2CFYNU")
    end
  end

  def test_return_video_by_url
    VCR.use_cassette("video_by_url") do
      video = @client.video_by("https://www.youtube.com/watch?v=EkF4JD2rO3Q")
      assert_valid_video video
    end
  end

  def test_configure_faraday_adapter
    assert YouTubeIt.adapter == Faraday.default_adapter
    YouTubeIt.adapter = :net_http
    assert YouTubeIt.adapter == :net_http
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
    assert_valid_url video.unique_id
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

  def assert_valid_url(url)
    URI::parse(url)
    return true
  rescue
    return false
  end
end
