# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require File.dirname(__FILE__) + "/lib/youtube_it/version"

Gem::Specification.new do |s|
  s.name        = "youtube_it"
  s.version     = YouTubeIt::VERSION
  s.authors     = ["kylejginavan", "chebyte", "mseppae"]
  s.date        = %q{2012-03-16}
  s.description = %q{Upload, delete, update, comment on youtube videos all from one gem.}
  s.email       = %q{kylejginavan@gmail.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "Gemfile",
    "Gemfile.lock",
    "Manifest.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/youtube_it.rb",
    "lib/youtube_it/chain_io.rb",
    "lib/youtube_it/client.rb",
    "lib/youtube_it/middleware/faraday_authheader.rb",
    "lib/youtube_it/middleware/faraday_oauth.rb",
    "lib/youtube_it/middleware/faraday_oauth2.rb",
    "lib/youtube_it/middleware/faraday_youtubeit.rb",
    "lib/youtube_it/model/activity.rb",
    "lib/youtube_it/model/author.rb",
    "lib/youtube_it/model/category.rb",
    "lib/youtube_it/model/comment.rb",
    "lib/youtube_it/model/contact.rb",
    "lib/youtube_it/model/content.rb",
    "lib/youtube_it/model/message.rb",
    "lib/youtube_it/model/playlist.rb",
    "lib/youtube_it/model/rating.rb",
    "lib/youtube_it/model/subscription.rb",
    "lib/youtube_it/model/thumbnail.rb",
    "lib/youtube_it/model/user.rb",
    "lib/youtube_it/model/video.rb",
    "lib/youtube_it/parser.rb",
    "lib/youtube_it/record.rb",
    "lib/youtube_it/request/base_search.rb",
    "lib/youtube_it/request/error.rb",
    "lib/youtube_it/request/standard_search.rb",
    "lib/youtube_it/request/user_search.rb",
    "lib/youtube_it/request/video_search.rb",
    "lib/youtube_it/request/video_upload.rb",
    "lib/youtube_it/response/video_search.rb",
    "lib/youtube_it/version.rb",
    "test/files/recorded_response.xml",
    "test/files/youtube_video_response.xml",
    "test/helper.rb",
    "test/test.mov",
    "test/test_chain_io.rb",
    "test/test_client.rb",
    "test/test_field_search.rb",
    "test/test_video.rb",
    "test/test_video_feed_parser.rb",
    "test/test_video_search.rb",
    "youtube_it.gemspec"
  ]
  s.homepage         = %q{http://github.com/kylejginavan/youtube_it}
  s.require_paths    = ["lib"]
  s.summary          = %q{The most complete Ruby wrapper for youtube api's}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<oauth>, ["~> 0.4.4"])
      s.add_runtime_dependency(%q<oauth2>, ["~> 0.6"])
      s.add_runtime_dependency(%q<simple_oauth>, ["~> 0.1.5"])
      s.add_runtime_dependency(%q<faraday>, ["~> 0.8"])
      s.add_runtime_dependency(%q<builder>, [">= 0"])
    else
      s.add_dependency(%q<oauth>, ["~> 0.4.4"])
      s.add_dependency(%q<oauth2>, ["~> 0.6"])
      s.add_dependency(%q<simple_oauth>, ["~> 0.1.5"])
      s.add_dependency(%q<faraday>, ["~> 0.8"])
      s.add_dependency(%q<builder>, [">= 0"])
    end
  else
    s.add_dependency(%q<oauth>, ["~> 0.4.4"])
    s.add_dependency(%q<oauth2>, ["~> 0.6"])
    s.add_dependency(%q<simple_oauth>, ["~> 0.1.5"])
    s.add_dependency(%q<faraday>, ["~> 0.8"])
    s.add_dependency(%q<builder>, [">= 0"])
  end
end

