# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require File.dirname(__FILE__) + "/lib/youtube_it/version"

Gem::Specification.new do |s|
  s.name        = "youtube_it"
  s.version     = YouTubeIt::VERSION
  s.authors     = %w(kylejginavan chebyte)
  s.email       = %w(kylejginavan@gmail.com maurotorres@gmail.com)
  s.description = "Upload, delete, update, comment on youtube videos all from one gem."
  s.summary     = "The most complete Ruby wrapper for youtube api's"
  s.homepage    = "http://github.com/kylejginavan/youtube_it"

  s.add_runtime_dependency("nokogiri", "~> 1.6.0")
  s.add_runtime_dependency("oauth", "~> 0.4.4")
  s.add_runtime_dependency("oauth2", "~> 0.6")
  s.add_runtime_dependency("simple_oauth", ">= 0.1.5")
  s.add_runtime_dependency("faraday", ['>= 0.8', '< 0.10'])
  s.add_runtime_dependency("builder", ">= 0")
  s.add_runtime_dependency("excon")
  s.add_runtime_dependency("json", "~> 1.8")
  s.files = Dir.glob("lib/**/*") + %w(README.rdoc youtube_it.gemspec)

  s.extra_rdoc_files = %w(README.rdoc CHANGELOG.md)
end

