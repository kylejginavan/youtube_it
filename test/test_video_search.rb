require 'rubygems'
require 'test/unit'
require 'pp'

require 'youtube_g'

class TestVideoSearch < Test::Unit::TestCase
  def setup
    @client = YoutubeG::Client.new
  end

  def test_basic_query
    request = YoutubeG::Request::VideoSearch.new(:query => "christina ricci")
    response = @client.search_videos request
    pp response
  end
end
