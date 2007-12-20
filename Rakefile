require 'rubygems'
require 'hoe'
require 'lib/youtube_g'

Hoe.new('youtube-g', YouTubeG::VERSION) do |p|
  p.rubyforge_name = 'youtube-g'
  p.author = ["Shane Vitarana", "Walter Korman"]
  p.email = 'shanev@gmail.com'
  p.summary = 'Ruby client for the YouTube GData API'
  p.description = p.paragraphs_of('README.txt', 2..8).join("\n\n")
  p.url = 'http://rubyforge.org/projects/youtube-g/'
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.remote_rdoc_dir = ''
end

desc 'Tag release'
task :tag do
  svn_root = 'svn+ssh://drummr77@rubyforge.org/var/svn/youtube-g'
  sh %(svn cp #{svn_root}/trunk #{svn_root}/tags/release-#{YouTubeG::VERSION} -m "Tag YouTubeG release #{YouTubeG::VERSION}")
end