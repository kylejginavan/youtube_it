== DESCRIPTION:

youtube_it is a pure Ruby client for the YouTube GData API. It provides an easy
way to access the latest YouTube video search results from your own programs.
In comparison with the earlier Youtube search interfaces, this new API and
library offers much-improved flexibility around executing complex search
queries to obtain well-targeted video search results.

== SYNOPSIS:

Create a client:

  require 'youtube_it'
  client = YouTubeIt::Client.new

Basic queries:

  client.videos_by(:query => "penguin")
  client.videos_by(:query => "penguin", :page => 2, :per_page => 15)
  client.videos_by(:tags => ['tiger', 'leopard'])
  client.videos_by(:categories => [:news, :sports])
  client.videos_by(:categories => [:news, :sports], :tags => ['soccer', 'football'])
  client.videos_by(:user => 'liz')
  client.videos_by(:favorites, :user => 'liz')
  client.video_by("FQK1URcxmb4")
  client.video_by_user("chebyte","FQK1URcxmb4")

Standard feeds:

  client.videos_by(:most_viewed)
  client.videos_by(:most_linked, :page => 3)
  client.videos_by(:top_rated, :time => :today)

Advanced queries (with boolean operators OR (either), AND (include), NOT (exclude)):

  client.videos_by(:categories => { :either => [:news, :sports], :exclude => [:comedy] }, :tags => { :include => ['football'], :exclude => ['soccer'] })


Upload videos:
  You need on youtube account and developer key
  You can get these keys at the http://code.google.com/apis/youtube/dashboard/

  client = YouTubeIt::Client.new("youtube_username", "youtube_passwd", "developer_key")

* upload video

  client.video_upload(File.open("test.mov"), :title => "test",:description => 'some description', :category => 'People',:keywords => %w[cool blah test])

* update video

  client.video_update("FQK1URcxmb4", :title => "new test",:description => 'new description', :category => 'People',:keywords => %w[cool blah test])

* delete video

  client.video_delete("FQK1URcxmb4")


Comments

  You can add or list comments with the following way:

  client = YouTubeIt::Client.new("youtube_username", "youtube_passwd", "developer_key")

*  get all comments:

  client.comments(video_id)

*  add a new comment:

  client.add_comment(video_id, "test comment!")

Access Control List

  You can give permissions in your videos, for example denied comments, rate, etc...
  you can read more there http://code.google.com/apis/youtube/2.0/reference.html#youtube_data_api_tag_yt:accessControl
  you have available the followings options:

* :rate, :comment, :commentVote, :videoRespond, :list, :embed, :syndicate

  Example

  client = YouTubeIt::Client.new("youtube_username", "youtube_passwd", "developer_key")

* upload video with denied comments

  client.video_upload(File.open("test.mov"), :title => "test",:description => 'some description', :category => 'People',:keywords => %w[cool blah test], :comment => "denied")


== Upload videos from browser:

 For upload a video from browser you need make a form upload with the followings params

    upload_token(params, nexturl)

    params  => params like :title => "title", :description => "description", :category => "People", :tags => ["test"]
    nexturl => redirect to this url after upload

   Example

   Controller:

    def upload
      @upload_info = YouTubeIt::Client.new.upload_token(params, videos_url)
    end

   Views: upload.html.erb

    <% form_tag @upload_info[:url], :multipart => true do %>
      <%= hidden_field_tag :token, @upload_info[:token] %>
      <%= label_tag :file %>
      <%= file_field_tag :file %>
      <%= submit_tag "Upload video" %>
    <% end %>

== LOGGING

YouTubeIt passes all logs through the logger variable on the class itself. In Rails context, assign the Rails logger to that variable to collect the messages
(don't forget to set the level to debug):

 YouTubeIt.logger = RAILS_DEFAULT_LOGGER
 RAILS_DEFAULT_LOGGER.level = Logger::DEBUG

== REQUIREMENTS:

* builder gem

== INSTALL:

* sudo gem install youtube_it
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

