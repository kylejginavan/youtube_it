require 'rubygems'
require 'hoe'
require 'lib/youtube_g/version'

Hoe.new('youtube-g', YouTubeG::VERSION) do |p|
  p.rubyforge_name = 'youtube-g'
  p.author = ["Shane Vitarana", "Walter Korman", "Aman Gupta", "Filip H.F. Slagter", "msp"]
  p.email = 'shanev@gmail.com'
  p.summary = 'Ruby client for the YouTube GData API'
  p.url = 'http://rubyforge.org/projects/youtube-g/'
  p.extra_deps << 'builder'
  p.remote_rdoc_dir = ''
end

desc 'Tag release'
task :tag do
  svn_root = 'svn+ssh://drummr77@rubyforge.org/var/svn/youtube-g'
  sh %(svn cp #{svn_root}/trunk #{svn_root}/tags/release-#{YouTubeG::VERSION} -m "Tag YouTubeG release #{YouTubeG::VERSION}")
end

desc 'Load the library in an IRB session'
task :console do
  sh %(irb -r lib/youtube_g.rb)
end