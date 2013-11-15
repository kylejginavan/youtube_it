#encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestClient < Test::Unit::TestCase

  OPTIONS = {:title => "test title",
             :description => "test description",
             :category => 'People',
             :keywords => %w[test]}
  RAILS_ENV = "test"

  def setup
    VCR.use_cassette("login with oauth2") do
      @client = YouTubeIt::OAuth2Client.new(:client_access_token => "ya29.AHES6ZSRC7Fa5cyUa5G5-TJtt849dQ7OdSiB_kjBQg7S", 
        :client_id => "68330730158.apps.googleusercontent.com", :client_secret => "Npj4rmtme7q6INPPQjpQFuCZ", :dev_key => "AI39si7WuZZxAkYebKSyrlJR7hIFktt6OoPycEOeOT_yHkZgr6QsGbZgmhKvbS4bsSAv0utgrfhNfXQBITu1wX_z3VsZE02giQ", :client_refresh_token => "1/ErxjeSs0RNMMGtaI-87grQf_o1iQKlx0JLwec1KIDH8")
      @client.refresh_access_token!
    end
    use_vcr
  end

  def teardown
    stop_vcr
  end

  def test_should_respond_to_a_basic_query
    response = @client.videos_by(:query => "penguin")
    assert_equal "tag:youtube.com,2008:videos", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 25, response.videos.length
    assert_equal 1, response.offset
    assert_instance_of Time, response.updated_at

    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_respond_to_a_basic_query_with_offset_and_max_results
    response = @client.videos_by(:query => "penguin", :offset => 15, :max_results => 30)

    assert_equal "tag:youtube.com,2008:videos", response.feed_id
    assert_equal 30, response.max_result_count
    assert_equal 30, response.videos.length
    assert_equal 15, response.offset
    assert_instance_of Time, response.updated_at

    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_respond_to_a_basic_query_with_paging
    response = @client.videos_by(:query => "penguin")
    assert_equal "tag:youtube.com,2008:videos", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 1, response.offset

    response = @client.videos_by(:query => "penguin", :page => 2)
    assert_equal "tag:youtube.com,2008:videos", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 26, response.offset

    response2 = @client.videos_by(:query => "penguin", :page => 3)
    assert_equal "tag:youtube.com,2008:videos", response2.feed_id
    assert_equal 25, response2.max_result_count
    assert_equal 51, response2.offset
  end

  def test_should_get_videos_for_multiword_metasearch_query
    response = @client.videos_by(:query => 'christina ricci')

    assert_equal "tag:youtube.com,2008:videos", response.feed_id
    assert_equal 25, response.max_result_count
    assert_equal 25, response.videos.length
    assert_equal 1, response.offset
    assert_instance_of Time, response.updated_at

    response.videos.each { |v| assert_valid_video v }
  end

  def test_should_handle_video_not_yet_viewed
    response = @client.videos_by(:query => "CE62FSEoY28")

    assert_equal 1, response.videos.length
    response.videos.each { |v| assert_valid_video v }
  end

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
    response = @client.videos_by(:favorites, :user => 'chebyte2006')
    assert_equal "tag:youtube.com,2008:user:chebyte2006:favorites", response.feed_id
    assert_valid_video response.videos.first
  end

  def test_should_get_videos_for_query_search_with_categories_excluded
    video = @client.video_by("EkF4JD2rO3Q")
    assert_equal "<object width=\"425\" height=\"350\">\n  <param name=\"movie\" value=\"http://www.youtube.com/v/EkF4JD2rO3Q&feature=youtube_gdata_player\"></param>\n  <param name=\"wmode\" value=\"transparent\"></param>\n  <embed src=\"http://www.youtube.com/v/EkF4JD2rO3Q&feature=youtube_gdata_player\" type=\"application/x-shockwave-flash\"\n   wmode=\"transparent\" width=\"425\" height=\"350\"></embed>\n</object>\n", video.embed_html
    assert_valid_video video
  end

  def test_should_get_video_from_user
    video = @client.video_by_user("chebyte","FQK1URcxmb4")
    assert_equal "<object width=\"425\" height=\"350\">\n  <param name=\"movie\" value=\"http://www.youtube.com/v/FQK1URcxmb4&feature=youtube_gdata_player\"></param>\n  <param name=\"wmode\" value=\"transparent\"></param>\n  <embed src=\"http://www.youtube.com/v/FQK1URcxmb4&feature=youtube_gdata_player\" type=\"application/x-shockwave-flash\"\n   wmode=\"transparent\" width=\"425\" height=\"350\"></embed>\n</object>\n", video.embed_html
    assert_valid_video video
  end

  def test_should_get_embed_video_for_html5
    video = @client.video_by_user("chebyte","FQK1URcxmb4")
    embed_html5 = video.embed_html5({:class => 'video-player', :id => 'my-video', :width => '425', :height => '350', :frameborder => '1', :url_params => {:option => "value"}})
    assert_equal "<iframe class=\"video-player\" id=\"my-video\" type=\"text/html\" width=\"425\" height=\"350\" src=\"http://www.youtube.com/embed/FQK1URcxmb4?option=value\" frameborder=\"1\"  ></iframe>\n", embed_html5
  end

  def test_should_always_return_a_logger
    @client = YouTubeIt::Client.new
    assert_not_nil @client.logger
  end

  def test_should_not_bail_if_debug_is_true
    assert_nothing_raised { YouTubeIt::Client.new(:debug => true) }
  end

  def test_should_determine_if_embeddable_video_is_embeddable
    response = @client.videos_by(:query => "strongbad")

    video = response.videos.first
    assert video.embeddable?
  end

  def test_should_retrieve_video_by_id
    video = @client.video_by("http://gdata.youtube.com/feeds/videos/EkF4JD2rO3Q")
    assert_valid_video video

    video = @client.video_by("http://www.youtube.com/watch?v=CBvFZV-jdHY")
    assert_valid_video video

    video = @client.video_by("EkF4JD2rO3Q")
    assert_valid_video video
  end

  def test_should_return_upload_info_for_upload_from_browser
    response = @client.upload_token(OPTIONS)
    assert response.kind_of?(Hash)
    assert_equal response.size, 2
    response.each do |k,v|
      assert v
    end
  end

  def test_should_upload_and_update_a_video
    video  = @client.video_upload(File.open("test/test.mov"), OPTIONS)
    assert_valid_video video
    assert video.listed?
    updated_video = @client.video_update(video.unique_id, OPTIONS.merge(:title => "title changed", :private => true, :latitude => 0.5, :longitude => 1.2))
    assert_equal "title changed", updated_video.title
    assert_equal 0.5, updated_video.latitude
    assert_equal 1.2, updated_video.longitude
    assert updated_video.perm_private
    assert @client.video_delete(video.unique_id)
  end

  def test_should_upload_and_partial_update_a_video
    video  = @client.video_upload(File.open("test/test.mov"), OPTIONS)
    assert_valid_video video
    assert video.listed?
    updated_video = @client.video_partial_update(video.unique_id, :list => 'denied', :embed => 'allowed')
    assert updated_video.embeddable?
    assert !updated_video.listed?
    assert @client.video_delete(video.unique_id)
  end

  def test_should_denied_comments
    video     = @client.video_upload(File.open("test/test.mov"), OPTIONS.merge(:comment => "denied"))
    assert_valid_video video
    doc = Excon.get("http://www.youtube.com/watch?hl=en&v=#{video.unique_id}").body
    assert !doc.match("<div id=\"comments-view\" class=\"comments-disabled\">").nil?, 'comments are not disabled'
    @client.video_delete(video.unique_id)
  end

  def test_should_denied_rate
    video  = @client.video_upload(File.open("test/test.mov"), OPTIONS.merge(:rate => "denied"))
    assert_valid_video video
    doc = Excon.get("http://www.youtube.com/watch?hl=en&v=#{video.unique_id}").body
    assert !doc.match("Ratings have been disabled for this video.").nil?, 'rating is not disabled'
    @client.video_delete(video.unique_id)
  end

  def test_should_denied_embed
    video  = @client.video_upload(File.open("test/test.mov"), OPTIONS.merge(:embed => "denied"))
    assert_valid_video video
    assert video.noembed
    @client.video_delete(video.unique_id)
  end

  def test_should_denied_listing
    video = @client.video_upload(File.open("test/test.mov"), OPTIONS.merge(:list => "denied"))
    assert_valid_video video
    assert !video.listed?
    @client.video_delete(video.unique_id)
  end

  def test_should_upload_private_video
    video  = @client.video_upload(File.open("test/test.mov"), OPTIONS.merge!(:private => true))
    assert_valid_video video
    assert_equal video.perm_private, true
    assert_equal video.access_control, {"comment"=>"allowed", "commentVote"=>"allowed", "videoRespond"=>"moderated", "rate"=>"allowed", "embed"=>"allowed", "list"=>"allowed", "autoPlay"=>"allowed", "syndicate"=>"allowed"}
    @client.video_delete(video.unique_id)
  end

  def test_should_add_comment_and_reply
    video  = @client.video_upload(File.open("test/test.mov"), OPTIONS)
    # Add comment
    res = @client.add_comment(video.unique_id, "test comment")
    assert_equal 201, res[:code]
    wait_for_api
    sleep(5)
    comment1 = @client.comments(video.unique_id).first
    assert_same_comment comment1, res[:comment]
    assert_equal "test comment", comment1.content
    assert_nil comment1.reply_to
    # Add reply
    res = @client.add_comment(video.unique_id, "reply comment", :reply_to => comment1)
    assert_equal 201, res[:code]
    wait_for_api
    sleep(5)
    comment2 = @client.comments(video.unique_id).find {|c| c.content =~ /reply/}
    assert_same_comment comment2, res[:comment]
    assert_equal "reply comment", comment2.content
    assert_equal comment1.unique_id, comment2.reply_to
    # Delete comment
    assert @client.delete_comment(video.unique_id, comment2)
    assert @client.delete_comment(video.unique_id, comment1.unique_id)
    wait_for_api
    sleep(5)
    @client.video_delete(video.unique_id)
  end

  def test_should_add_and_delete_video_from_playlist
    @client.playlists.each{|p| @client.delete_playlist(p.playlist_id)}
    playlist = @client.add_playlist(:title => "youtube_it test!", :description => "test playlist")
    video = @client.add_video_to_playlist(playlist.playlist_id,"CE62FSEoY28")
    assert_equal video[:code].to_i, 201
    assert @client.delete_video_from_playlist(playlist.playlist_id, video[:playlist_entry_id])
    assert @client.delete_playlist(playlist.playlist_id)
  end

  def test_should_update_position_video_from_playlist
    @client.playlists.each{|p| @client.delete_playlist(p.playlist_id)}
    playlist = @client.add_playlist(:title => "youtube_it test!", :description => "test playlist")
    video = @client.add_video_to_playlist(playlist.playlist_id, "CE62FSEoY28", 1)
    assert_equal video[:code].to_i, 201
    assert_equal YouTubeIt::Parser::VideosFeedParser.new(video[:body]).parse_videos.last.video_position.to_i, 1

    video = @client.add_video_to_playlist(playlist.playlist_id, "CE62FSEoY28", 2)
    assert_equal video[:code].to_i, 201
    assert_equal YouTubeIt::Parser::VideosFeedParser.new(video[:body]).parse_videos.last.video_position.to_i, 2

    video = @client.update_position_video_from_playlist(playlist.playlist_id, video[:playlist_entry_id], 2)
    assert_equal video[:code].to_i, 200
    assert_equal YouTubeIt::Parser::VideosFeedParser.new(video[:body]).parse_videos.last.video_position.to_i, 2

    assert @client.delete_video_from_playlist(playlist.playlist_id, video[:playlist_entry_id])
    assert @client.delete_playlist(playlist.playlist_id)
  end

  def test_should_return_unique_id_from_playlist
    @client.playlists.each{|p| @client.delete_playlist(p.playlist_id)}
    playlist = @client.add_playlist(:title => "youtube_it test0!", :description => "test playlist")
    video = @client.add_video_to_playlist(playlist.playlist_id,"CE62FSEoY28")
    wait_for_api
    playlist = @client.playlist(playlist.playlist_id)
    assert_equal "CE62FSEoY28", playlist.videos.last.unique_id
    assert @client.delete_video_from_playlist(playlist.playlist_id, video[:playlist_entry_id])
    assert @client.delete_playlist(playlist.playlist_id)
  end

  def test_should_add_and_delete_new_playlist
    @client.playlists.each{|p| @client.delete_playlist(p.playlist_id)}
    result = @client.add_playlist(:title => "youtube_it test1!", :description => "test playlist")
    assert result.title, "youtube_it test!"
    wait_for_api
    playlist = @client.playlist(result.playlist_id)
    assert @client.delete_playlist(result.playlist_id)
  end

  def test_should_update_playlist
    @client.playlists.each{|p| @client.delete_playlist(p.playlist_id)}
    playlist = @client.add_playlist(:title => "youtube_it test2!", :description => "test playlist")
    wait_for_api
    playlist = @client.playlist(playlist.playlist_id)
    playlist_updated = @client.update_playlist(playlist.playlist_id, :title => "title changed")
    assert_equal playlist_updated.title, "title changed"
    assert @client.delete_playlist(playlist.playlist_id)
  end

  def test_should_list_playlist_for_user
    result = @client.playlists('chebyte')
    assert_equal "rock", result.last.title
  end

  def test_should_determine_if_widescreen_video_is_widescreen
    widescreen_id = 'QqQVll-MP3I'
    video = @client.video_by(widescreen_id)
    assert video.widescreen?
  end

  def test_should_get_current_user
    assert_equal 'tubeit20101', @client.current_user
  end

  def test_should_get_my_videos
    video  = @client.video_upload(File.open("test/test.mov"), OPTIONS)
    assert_valid_video video
    wait_for_api
    result = @client.my_videos
    assert_equal video.unique_id, result.videos.first.unique_id
    assert_not_nil result.videos.first.insight_uri, 'insight data not present'
    result = @client.my_video(video.unique_id)
    assert_equal video.unique_id, result.unique_id
    @client.video_delete(video.unique_id)
  end

  def test_should_raise_error_on_video_not_found
    exception = assert_raise(YouTubeIt::ResourceNotFoundError) { @client.my_video("nonexisting") }
    assert_equal 404, exception.code
    assert_equal "Video not found: ResourceNotFoundException\n", exception.message
  end

  def test_should_raise_error_on_private_video
    exception = assert_raise(YouTubeIt::AuthenticationError) { @client.my_video("0KI_osldHWg") }
    assert_equal 403, exception.code
    assert_equal "Private video: ServiceForbiddenException\n", exception.message
  end

  def test_should_add_like_to_video
    r = @client.like_video("CE62FSEoY28")
    assert_equal r[:code], 201
    @client.dislike_video("CE62FSEoY28")
  end

  def test_should_dislike_to_video
    @client.like_video("CE62FSEoY28")
    r = @client.dislike_video("CE62FSEoY28")
    assert_equal r[:code], 201
  end

  def test_should_subscribe_list_and_unsubscribe_to_channel
    @client.subscriptions.each {|s| @client.unsubscribe_channel(s.id) }
    wait_for_api
    sleep(5)
    subscribe = @client.subscribe_channel("Magicurzay1")
    assert_equal subscribe[:code], 201
    wait_for_api
    sleep(5)
    subs = @client.subscriptions
    assert_equal subs.first.title, "Videos published by: Magicurzay1"
    assert_not_nil subs.first.id
    unsubscribe = @client.unsubscribe_channel(subs.first.id)
    assert_equal unsubscribe[:code], 200
  end

  def test_should_get_profile
    profile = @client.profile
    assert_equal profile.username, "tubeit20101"
    assert_not_nil profile.insight_uri, 'user insight_uri nil'

    assert_equal 'tubeit20101', profile.username
    assert_equal 'tubeit20101', profile.username_display
    assert_equal 'http://www.youtube.com/channel/UCWWmLvppy3j64IGmA2dpCyw', profile.channel_uri
    assert_instance_of Fixnum, profile.max_upload_duration
    assert_instance_of String, profile.user_id
    assert_nothing_raised{ profile.last_name }
    assert_nothing_raised{ profile.first_name }
    assert_instance_of Fixnum, profile.upload_count
  end

  def test_should_get_another_profile
    profile = @client.profile('honda')
    assert_equal profile.username, "honda"
    assert_nil profile.insight_uri, 'DANGER: user insight_uri not nil for unauthed user; leaking private data?'
  end

  def test_should_get_multi_profiles
    profiles = @client.profiles ['tubeit20101', 'honda','some_non-existing_username']
    assert_operator profiles, :has_key?, 'tubeit20101'
    assert_equal profiles['tubeit20101'].username, "tubeit20101"
    assert_not_nil profiles['tubeit20101'].insight_uri, 'user insight_uri nil for authed user'

    assert_operator profiles, :has_key?, 'honda'
    assert_equal profiles['honda'].username, "honda"
    assert_nil profiles['honda'].insight_uri, 'DANGER: user insight_uri not nil for unauthed user; leaking private data?'

    assert_operator profiles, :has_key?, 'some_non-existing_username'
    assert_nil profiles['some_non-existing_username']
  end

  def test_should_get_multi_videos
    videos = @client.videos ['82Wg7DYG9Jc', 'AByfaYcOm4A']
    assert_operator videos, :has_key?, 'AByfaYcOm4A'
    assert_equal videos['82Wg7DYG9Jc'].title, 'Billboard Hot 100 - Top 50 Singles (4/20/2013)'
  end

  def test_should_add_and_delete_video_to_favorite
    video_id ="fFAnoEYFUQw"
    begin
      result = @client.add_favorite(video_id)
    rescue
      @client.delete_favorite(result[:favorite_entry_id])
      wait_for_api
      result = @client.add_favorite(video_id)
    end
    assert_equal 201, result[:code]
    assert @client.delete_favorite(result[:favorite_entry_id])
  end

  def test_unicode_query
    videos = @client.videos_by(:query => 'спят усталые игрушки').videos
    assert videos.any?
  end

  def test_return_video_by_url
    video = @client.video_by("https://www.youtube.com/watch?v=EkF4JD2rO3Q")
    assert_valid_video video
  end

  def test_safe_search_params
    @videos = @client.videos_by(:query => "porno", :safe_search => 'none').videos
    assert_equal @videos.count, 25
    @videos = @client.videos_by(:query => "porno", :safe_search => 'strict').videos
    assert_equal @videos.count, 0
  end

  def test_playlists_order
    @client.playlists.each{|p| @client.delete_playlist(p.playlist_id)}
    playlist = @client.add_playlist(:title => "youtube_it test!", :description => "test playlist")

    video_one = @client.add_video_to_playlist(playlist.playlist_id,"fFAnoEYFUQw")
    video_two = @client.add_video_to_playlist(playlist.playlist_id,"QsbmrCtiEUU")
    wait_for_api
    assert_equal ["fFAnoEYFUQw", "QsbmrCtiEUU"], @client.playlist(playlist.playlist_id, { 'orderby' => 'title' }).videos.map(&:unique_id)
    assert @client.delete_video_from_playlist(playlist.playlist_id, video_one[:playlist_entry_id])
    assert @client.delete_video_from_playlist(playlist.playlist_id, video_two[:playlist_entry_id])
    assert @client.delete_playlist(playlist.playlist_id)
  end

  def test_playlist_with_paging_parameters
    @client.playlists.each{|p| @client.delete_playlist(p.playlist_id)}
    playlist = @client.add_playlist(:title => "youtube_it test!", :description => "test playlist")

    video_one = @client.add_video_to_playlist(playlist.playlist_id,"fFAnoEYFUQw")
    video_two = @client.add_video_to_playlist(playlist.playlist_id,"QsbmrCtiEUU")
    wait_for_api
    assert_equal ["fFAnoEYFUQw"], @client.playlist(playlist.playlist_id, { 'orderby' => 'title', 'start-index' => 1, 'max-results' => 1 }).videos.map(&:unique_id)
    assert_equal ["QsbmrCtiEUU"], @client.playlist(playlist.playlist_id, { 'orderby' => 'title', 'start-index' => 2, 'max-results' => 1 }).videos.map(&:unique_id)
    assert @client.delete_video_from_playlist(playlist.playlist_id, video_one[:playlist_entry_id])
    assert @client.delete_video_from_playlist(playlist.playlist_id, video_two[:playlist_entry_id])
    assert @client.delete_playlist(playlist.playlist_id)
  end

  def test_playlists_with_paging_parameters
    playlists_first_page = @client.playlists('sbnation', {'start-index' => 1, 'max-results' => 25})
    assert_equal 25, playlists_first_page.size

    playlists_second_page = @client.playlists('sbnation', {'start-index' => 26, 'max-results' => 25})
    assert_equal 13, playlists_second_page.size

    all_playlists = playlists_first_page + playlists_second_page
    assert_equal all_playlists.size, all_playlists.uniq.size
  end

  def test_all_playlists
    all_playlists = @client.all_playlists('sbnation')
    assert_equal 38, all_playlists.size
  end

  def test_should_add_and_delete_video_from_watchlater
    # Clear list
    @client.watchlater.videos.each {|v| @client.delete_video_from_watchlater(v.watch_later_id)}
    wait_for_api
    video = @client.add_video_to_watchlater("fFAnoEYFUQw")
    wait_for_api
    playlist = @client.watchlater
    assert playlist
    assert_equal 1, playlist.videos.size
    assert_equal playlist.videos.first.unique_id, "fFAnoEYFUQw"
    @client.delete_video_from_watchlater(video[:watchlater_entry_id])
    wait_for_api
    assert @client.watchlater.videos.empty?
  end

  def test_batch_videos
    videos = @client.videos(['oFT7vWyC1Ys', '1m3HDHZx4xM'])
    assert_equal videos.count, 2
  end

  def test_get_all_videos
    videos = @client.get_all_videos(:user => "enchufetv")
    assert_equal videos.count, 199
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
      assert_instance_of Time, video.updated_at
      assert_instance_of Time, video.uploaded_at

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

      # validate comment & view counts
      assert_instance_of Fixnum, video.comment_count
      assert_instance_of Fixnum, video.view_count

      # validate access_control
      assert_instance_of Hash, video.access_control
      assert_operator video.access_control, :has_key?, 'comment'
      assert_operator ['allowed','moderated','denied'], :include?, video.access_control['comment']
    end

    def assert_same_comment c1, c2
      assert_equal c1.unique_id, c2.unique_id
      assert_equal c1.content, c2.content
      assert_equal c1.published, c2.published
      assert_equal c1.reply_to, c2.reply_to
      assert_equal c1.title, c2.title
      assert_equal c1.updated, c2.updated
      assert_equal c1.url, c2.url
      assert_equal c1.author.name, c2.author.name
      assert_equal c1.channel_id, c2.channel_id
      assert_equal c1.gp_user_id, c2.gp_user_id
    end

    def assert_valid_url (url)
      URI::parse(url)
      return true
    rescue
      return false
    end
end
