require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "youtube_it"
    gem.summary = %Q{The most complete Ruby wrapper for youtube api's}
    gem.description = %Q{Upload, delete, update, comment on youtube videos all from one gem.}
    gem.email = "kylejginavan@gmail.com"
    gem.homepage = "http://github.com/kylejginavan/youtube_it"
    gem.add_dependency('oauth','>=0.4.4')
    gem.add_dependency('simple_oauth', '>=0.1.5')    
    gem.add_dependency('faraday','>=0.7.3')    
    gem.add_dependency('builder')
    gem.authors = ["kylejginavan","chebyte", "mseppae"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "youtube_it (or a dependency) not available. Install it with: gem install youtube_it"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "constantations #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

