#encoding: utf-8

require 'webmock/test_unit'

require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestVideo < Test::Unit::TestCase

  def setup
    @client = YouTubeIt::Client.new
  end

  def test_esc
    result = YouTubeIt.esc("спят усталые игрушки")
    assert result == "спят+усталые+игрушки"
  end

  def test_unicode_query
    @client.videos_by(:query => 'спят усталые игрушки')
  end
end
