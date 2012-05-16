#encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestYoutubeit < Test::Unit::TestCase
  def test_esc
    result = YouTubeIt.esc("спят усталые игрушки")
    assert_equal "%D1%81%D0%BF%D1%8F%D1%82+%D1%83%D1%81%D1%82%D0%B0%D0%BB%D1%8B%D0%B5+%D0%B8%D0%B3%D1%80%D1%83%D1%88%D0%BA%D0%B8", result
  end

  def test_should_encode_ampersand
    result = YouTubeIt.esc("such & such")
    assert_equal "such+%26+such", result
  end

  def test_configure_faraday_adapter
    assert YouTubeIt.adapter == Faraday.default_adapter
    YouTubeIt.adapter = :net_http
    assert YouTubeIt.adapter == :net_http
  end
end