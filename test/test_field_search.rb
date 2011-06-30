require File.expand_path(File.dirname(__FILE__) + '/helper')

class YouTubeIt
  module Request
    class TestSearch < BaseSearch
      include FieldSearch

      def initialize(params={})
        @url = fields_to_params(params.delete(:fields))
      end 
    end
  end
end

class TestFieldSearch < Test::Unit::TestCase
  include YouTubeIt::Request

  def default_fields
    "id,updated,openSearch:totalResults,openSearch:startIndex,openSearch:itemsPerPage"
  end

  def test_should_search_for_range_of_recoreded_on_dates
    starts_at = Date.today - 4
    ends_at = Date.today
    request = TestSearch.new(:fields => {:recorded => (starts_at..ends_at)})
    assert_equal URI.escape("&fields=#{default_fields},entry[xs:date(yt:recorded) > xs:date('#{starts_at.strftime('%Y-%m-%d')}') and xs:date(yt:recorded) < xs:date('#{ends_at.strftime('%Y-%m-%d')}')]"), request.url
  end

 def test_should_search_for_recoreded_on_date
    recorded_at = Date.today
    request = TestSearch.new(:fields => {:recorded => recorded_at})
    assert_equal URI.escape("&fields=#{default_fields},entry[xs:date(yt:recorded) = xs:date('#{recorded_at.strftime('%Y-%m-%d')}')]"), request.url
  end

  def test_should_search_for_range_of_published_on_dates
    starts_at = Date.today - 4
    ends_at = Date.today
    request = TestSearch.new(:fields => {:published => (starts_at..ends_at)})
    assert_equal URI.escape("&fields=#{default_fields},entry[xs:dateTime(published) > xs:dateTime('#{starts_at.strftime('%Y-%m-%d')}T00:00:00') and xs:dateTime(published) < xs:dateTime('#{ends_at.strftime('%Y-%m-%d')}T00:00:00')]"), request.url
  end

 def test_search_for_published_on_date
    published_at = Date.today
    request = TestSearch.new(:fields => {:published => published_at})
    assert_equal URI.escape("&fields=#{default_fields},entry[xs:date(published) = xs:date('#{published_at.strftime('%Y-%m-%d')}')]"), request.url
 end
end

