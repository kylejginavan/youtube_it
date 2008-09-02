spec = Gem::Specification.new do |s|
  s.name = 'youtube-g'
  s.version = '0.4.9.9'
  s.date = '2008-09-01'
  s.summary = 'An object-oriented Ruby wrapper for the YouTube GData API'
  s.email = "ruby-youtube-library@googlegroups.com"
  s.homepage = "http://youtube-g.rubyforge.org/"
  s.description = "An object-oriented Ruby wrapper for the YouTube GData API"
  s.has_rdoc = true
  s.authors = ["Shane Vitarana", "Walter Korman", "Aman Gupta", "Filip H.F. Slagter"]

  # ruby -rpp -e "pp Dir['**/*.*'].map"
  s.files = [
    "History.txt",
     "lib/youtube_g/client.rb",
     "lib/youtube_g/logger.rb",
     "lib/youtube_g/model/author.rb",
     "lib/youtube_g/model/category.rb",
     "lib/youtube_g/model/contact.rb",
     "lib/youtube_g/model/content.rb",
     "lib/youtube_g/model/playlist.rb",
     "lib/youtube_g/model/rating.rb",
     "lib/youtube_g/model/thumbnail.rb",
     "lib/youtube_g/model/user.rb",
     "lib/youtube_g/model/video.rb",
     "lib/youtube_g/parser.rb",
     "lib/youtube_g/record.rb",
     "lib/youtube_g/request/base_search.rb",
     "lib/youtube_g/request/standard_search.rb",
     "lib/youtube_g/request/user_search.rb",
     "lib/youtube_g/request/video_search.rb",
     "lib/youtube_g/request/video_upload.rb",
     "lib/youtube_g/response/video_search.rb",
     "lib/youtube_g.rb",
     "Manifest.txt",
     "README.txt",
     "test/test_client.rb",
     "test/test_video.rb",
     "test/test_video_search.rb",
     "TODO.txt",
     "youtube-g.gemspec"
  ]

  s.test_files = [
    "test/test_client.rb",
    "test/test_video.rb",
    "test/test_video_search.rb"
  ]

  s.rdoc_options = ["--main", "README.txt"]
  s.extra_rdoc_files = ["History.txt", "README.txt"]
end
