require 'logger'
require 'open-uri'
require 'net/https'
require 'digest/md5'
require 'rexml/document'
require 'builder'
require 'oauth'
require 'faraday'

class YouTubeIt
  
  # Base error class for the extension
  class Error < RuntimeError
  end
  
  # URL-escape a string. Stolen from Camping (wonder how many Ruby libs in the wild can say the same)
  def self.esc(s) #:nodoc:
    s.to_s.gsub(/[^ \w.-]+/n){'%'+($&.unpack('H2'*$&.size)*'%').upcase}.tr(' ', '+')
  end
  
  # Set the logger for the library
  def self.logger=(any_logger)
    @logger = any_logger
  end

  # Get the logger for the library (by default will log to STDOUT). TODO: this is where we grab the Rails logger too
  def self.logger
    @logger ||= create_default_logger
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
  model/playlist
  model/rating
  model/subscription
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
  response/video_search
  middleware/faraday_authheader.rb  
  middleware/faraday_oauth.rb  
  middleware/faraday_youtubeit.rb
  chain_io
).each{|m| require File.dirname(__FILE__) + '/youtube_it/' + m }
