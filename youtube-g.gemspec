Gem::Specification.new do |s|
  s.name = %q{youtube-g}
  s.version = "0.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Shane Vitarana", "Walter Korman", "Aman Gupta", "Filip H.F. Slagter", "msp"]
  s.date = %q{2009-03-02}
  s.description = %q{youtube-g is a pure Ruby client for the YouTube GData API. It provides an easy way to access the latest YouTube video search results from your own programs. In comparison with the earlier Youtube search interfaces, this new API and library offers much-improved flexibility around executing complex search queries to obtain well-targeted video search results.  More detail on the underlying source Google-provided API is available at:  http://code.google.com/apis/youtube/overview.html}
  s.email = %q{shanev@gmail.com}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt", "TODO.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "TODO.txt", "lib/youtube_g.rb", "lib/youtube_g/chain_io.rb", "lib/youtube_g/client.rb", "lib/youtube_g/model/author.rb", "lib/youtube_g/model/category.rb", "lib/youtube_g/model/contact.rb", "lib/youtube_g/model/content.rb", "lib/youtube_g/model/playlist.rb", "lib/youtube_g/model/rating.rb", "lib/youtube_g/model/thumbnail.rb", "lib/youtube_g/model/user.rb", "lib/youtube_g/model/video.rb", "lib/youtube_g/parser.rb", "lib/youtube_g/record.rb", "lib/youtube_g/request/base_search.rb", "lib/youtube_g/request/standard_search.rb", "lib/youtube_g/request/user_search.rb", "lib/youtube_g/request/video_search.rb", "lib/youtube_g/request/video_upload.rb", "lib/youtube_g/response/video_search.rb", "lib/youtube_g/version.rb", "test/helper.rb", "test/test_chain_io.rb", "test/test_client.rb", "test/test_video.rb", "test/test_video_search.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://rubyforge.org/projects/youtube-g/}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{youtube-g}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Ruby client for the YouTube GData API}
  s.test_files = ["test/test_chain_io.rb", "test/test_client.rb", "test/test_video.rb", "test/test_video_search.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<builder>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.3"])
    else
      s.add_dependency(%q<builder>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 1.8.3"])
    end
  else
    s.add_dependency(%q<builder>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 1.8.3"])
  end
end
