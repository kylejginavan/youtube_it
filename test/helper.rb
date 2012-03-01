require 'rubygems'
require 'date'
require 'test/unit'
require 'pp'
require 'open-uri'
require 'vcr'
require File.dirname(__FILE__) + '/../lib/youtube_it'

VCR.config do |c|
  c.cassette_library_dir = 'test/cassettes'
  c.stub_with :webmock
  c.default_cassette_options = { :record => :once }
end

YouTubeIt.logger.level = Logger::ERROR
