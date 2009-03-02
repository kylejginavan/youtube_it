= youtube-g

http://youtube-g.rubyforge.org/

== DESCRIPTION:

youtube-g is a pure Ruby client for the YouTube GData API. It provides an easy
way to access the latest YouTube video search results from your own programs.
In comparison with the earlier Youtube search interfaces, this new API and
library offers much-improved flexibility around executing complex search
queries to obtain well-targeted video search results.

More detail on the underlying source Google-provided API is available at:

http://code.google.com/apis/youtube/overview.html

== AUTHORS

Shane Vitarana and Walter Korman

== WHERE TO GET HELP

http://rubyforge.org/projects/youtube-g
http://groups.google.com/group/ruby-youtube-library
  
== FEATURES/PROBLEMS:
  
* Aims to be in parity with Google's YouTube GData API.  Core functionality
  is currently present -- work is in progress to fill in the rest.

== SYNOPSIS:

Create a client:
  
  require 'youtube_g'
  client = YouTubeG::Client.new
  
Basic queries:

  client.videos_by(:query => "penguin")
  client.videos_by(:query => "penguin", :page => 2, :per_page => 15)
  client.videos_by(:tags => ['tiger', 'leopard'])
  client.videos_by(:categories => [:news, :sports])
  client.videos_by(:categories => [:news, :sports], :tags => ['soccer', 'football'])
  client.videos_by(:user => 'liz')
  client.videos_by(:favorites, :user => 'liz')
	
Standard feeds:
	
  client.videos_by(:most_viewed)
  client.videos_by(:most_linked, :page => 3)
  client.videos_by(:top_rated, :time => :today)
	
Advanced queries (with boolean operators OR (either), AND (include), NOT (exclude)):
	
  client.videos_by(:categories => { :either => [:news, :sports], :exclude => [:comedy] }, :tags => { :include => ['football'], :exclude => ['soccer'] })

== LOGGING

YouTubeG passes all logs through the logger variable on the class itself. In Rails context, assign the Rails logger to that variable to collect the messages
(don't forget to set the level to debug):

 YouTubeG.logger = RAILS_DEFAULT_LOGGER
 RAILS_DEFAULT_LOGGER.level = Logger::DEBUG

== REQUIREMENTS:

* builder gem

== INSTALL:

* sudo gem install youtube-g

== LICENSE:

MIT License

Copyright (c) 2007 Shane Vitarana and Walter Korman

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
