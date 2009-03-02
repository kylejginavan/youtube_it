require 'logger'
require 'open-uri'
require 'net/https'
require 'digest/md5'
require 'rexml/document'
require 'builder'

class YouTubeG
  
  # Base error class for the extension
  class Error < RuntimeError
  end
  
  # URL-escape a string. Stolen from Camping (wonder how many Ruby libs in the wild can say the same)
  def self.esc(s) #:nodoc:
    s.to_s.gsub(/[^ \w.-]+/n){'%'+($&.unpack('H2'*$&.size)*'%').upcase}.tr(' ', '+')
  end
end

%w( 
  version
  client
  record
  parser
  model/author
  model/category
  model/contact
  model/content
  model/playlist
  model/rating
  model/thumbnail
  model/user
  model/video
  request/base_search
  request/user_search
  request/standard_search
  request/video_upload
  request/video_search
  response/video_search
  chain_io
).each{|m| require File.dirname(__FILE__) + '/youtube_g/' + m }