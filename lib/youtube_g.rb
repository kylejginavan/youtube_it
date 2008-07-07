require 'logger'
require 'open-uri'
require 'net/https'
require 'digest/md5'
require 'rexml/document'
require 'cgi'

ruby_files = Dir.glob( File.join(File.dirname(__FILE__), "/youtube_g/**", "*.rb") )
ruby_files.each { |file| require file }

class YouTubeG #:nodoc:
  VERSION = '0.4.5'
end
