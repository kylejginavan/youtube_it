require 'rubygems'
require 'hoe'
require 'lib/youtube_it/version'

Hoe.new('youtube_it', YouTubeIt::VERSION) do |p|
  p.rubyforge_name = 'youtube_it'
  p.author = ["Torres Mauro"]
  p.email = 'maurotorres@gmail.com'
  p.summary = 'Ruby client for the YouTube GData API based on youtube-g gem'
  p.url = 'http://rubyforge.org/projects/youtube-g/'
  p.extra_deps << 'builder'
  p.remote_rdoc_dir = ''
end

desc 'Load the library in an IRB session'
task :console do
  sh %(irb -r lib/youtube_g.rb)
end

