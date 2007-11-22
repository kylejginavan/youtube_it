# -*- ruby -*-

require 'rubygems'
require 'hoe'
$:.unshift(File.dirname(__FILE__) + "/lib")
require 'youtube_g'

Hoe.new('youtube-g', YouTubeG::VERSION) do |p|
  p.rubyforge_name = 'youtube-g'
  p.author = ["Shane Vitarana", "Walter Korman"]
  p.email = 'shanev@gmail.com'
  p.summary = 'Pure Ruby client for the YouTube GData API'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
end

# vim: syntax=Ruby
