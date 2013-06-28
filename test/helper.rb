require 'rubygems'
require 'date'
require 'test/unit'
require 'pp'
require 'open-uri'
require 'vcr'
require File.dirname(__FILE__) + '/../lib/youtube_it'

VCR.configure do |c|
  c.cassette_library_dir = 'test/cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
end

module VCRHelpers
  # Should be called from the setup method
  def use_vcr
    name = respond_to?(:method_name) ? method_name : __name__
    cassette = VCR.insert_cassette name.gsub(/test_(should_)?/, '')
    @wait = true if not File.file?(cassette.file)
  end

  # Should be called from the teardown method
  def stop_vcr
    VCR.eject_cassette
  end

  # This method wait for YouTube API to expire cache and give fresh data
  # Only when recording real API calls with VCR
  def wait_for_api
    sleep 4 if @wait
  end
end

class Test::Unit::TestCase
  include VCRHelpers
end

YouTubeIt.logger.level = Logger::ERROR