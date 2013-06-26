require 'logger'
require 'open-uri'
require 'net/https'
require 'digest/md5'
require 'nokogiri'
require 'builder'
require 'oauth'
require 'oauth2'
require 'faraday'

class YouTubeIt
  API_VERSION = "2.1"

  # Base error class for the extension
  class Error < RuntimeError
    attr_reader :code
    def initialize(msg, code = 0)
      super(msg)
      @code = code
    end
  end

  def self.esc(s) #:nodoc:
    CGI.escape(s.to_s)
  end

  # Set the logger for the library
  def self.logger=(any_logger)
    @logger = any_logger
  end

  # Get the logger for the library (by default will log to STDOUT). TODO: this is where we grab the Rails logger too
  def self.logger
    @logger ||= create_default_logger
  end

  def self.adapter=(faraday_adapter)
    @adapter = faraday_adapter
  end

  def self.adapter
    @adapter ||= Faraday.default_adapter
  end

  # Gets mixed into the classes to provide the logger method
  module Logging #:nodoc:

    # Return the base logger set for the library
    def logger
      YouTubeIt.logger
    end
  end

  private
    def self.create_default_logger
      logger = Logger.new(STDOUT)
      logger.level = Logger::DEBUG
      logger
    end
end

%w(
  version
  client
  record
  parser
  model/author
  model/category
  model/comment
  model/contact
  model/content
  model/message
  model/playlist
  model/rating
  model/subscription
  model/caption
  model/thumbnail
  model/user
  model/video
  model/activity
  request/base_search
  request/error
  request/user_search
  request/standard_search
  request/video_upload
  request/video_search
  request/remote_file
  response/video_search
  middleware/faraday_authheader.rb
  middleware/faraday_oauth.rb
  middleware/faraday_oauth2.rb
  middleware/faraday_youtubeit.rb
  chain_io
).each{|m| require File.dirname(__FILE__) + '/youtube_it/' + m }
