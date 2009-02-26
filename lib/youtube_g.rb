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

require File.dirname(__FILE__) + '/youtube_g/version'
require File.dirname(__FILE__) + '/youtube_g/client'
require File.dirname(__FILE__) + '/youtube_g/record'
require File.dirname(__FILE__) + '/youtube_g/parser'
require File.dirname(__FILE__) + '/youtube_g/model/author'
require File.dirname(__FILE__) + '/youtube_g/model/category'
require File.dirname(__FILE__) + '/youtube_g/model/contact'
require File.dirname(__FILE__) + '/youtube_g/model/content'
require File.dirname(__FILE__) + '/youtube_g/model/playlist'
require File.dirname(__FILE__) + '/youtube_g/model/rating'
require File.dirname(__FILE__) + '/youtube_g/model/thumbnail'
require File.dirname(__FILE__) + '/youtube_g/model/user'
require File.dirname(__FILE__) + '/youtube_g/model/video'
require File.dirname(__FILE__) + '/youtube_g/request/base_search'
require File.dirname(__FILE__) + '/youtube_g/request/user_search'
require File.dirname(__FILE__) + '/youtube_g/request/standard_search'
require File.dirname(__FILE__) + '/youtube_g/request/video_upload'
require File.dirname(__FILE__) + '/youtube_g/request/video_search'
require File.dirname(__FILE__) + '/youtube_g/response/video_search'
require File.dirname(__FILE__) + '/youtube_g/chain_io'
    