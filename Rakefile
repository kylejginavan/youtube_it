require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
<<<<<<< HEAD
    gem.name = "youtube_it"
    gem.summary = %Q{The most complete Ruby wrapper for youtube api's}
    gem.description = %Q{Upload, delete, update, comment on youtube videos all from one gem.}
    gem.email = "kylejginavan@gmail.com"
    gem.homepage = "http://github.com/kylejginavan/youtube_it"
    gem.authors = ["Mauro Torres & Kyle Ginavan"]
=======
    gem.name = "youtube_it_v2"
    gem.summary = %Q{the one stop shop for working with youtube apis (experimental: v2 api)}
    gem.description = %Q{the one stop shop for working with youtube apis (experimental: v2 api)}
    gem.email = "herestomwiththeweather@gmail.com"
    gem.homepage = "http://github.com/herestomwiththeweather/youtube_it"
    gem.authors = ["Mauro Torres & Kyle Ginavan","HeresTomWithTheWeather"]
>>>>>>> herestomwiththeweather/master
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "youtube_it (or a dependency) not available. Install it with: gem install youtube_it"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'spec'
  test.pattern = 'spec/**/*_spec.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'spec'
    test.pattern = 'spec/**/*_spec.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "constantations #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'spec/rake/spectask'
desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_opts = ['--colour --format progress --loadby mtime --reverse']
  t.spec_files = FileList['spec/**/*_spec.rb']
end

