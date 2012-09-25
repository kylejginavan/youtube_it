# YouTube\_It
[![Travis CI](https://secure.travis-ci.org/kylejginavan/youtube_it.png)](http://travis-ci.org/kylejginavan/youtube_it)

## Donations

youtube\_it is developed by many contributors who are passionate about opensource projects and selflessly donate their time and effort. Following that spirit, your donations to this project will be donated to the Tuquito Libre Foundation(http://fundacion.tuquito.org.ar) for developing technology projects intended to close the digital gap in Latin America.

[![Donate](https://www.pledgie.com/campaigns/16746.png?skin_name=chrome)](http://www.pledgie.com/campaigns/16746)

## Description

youtube\_it is the most complete Ruby client for the YouTube GData API. It provides an easy way to access YouTube's video API. Compared to earlier YouTube interfaces, this new API and library offers much-improved flexibility around executing complex search queries to obtain well-targeted video search results. Also included is standard video management such as uploading, deleting, updating, liking, disliking, ratings and comments.

## Installation & Setup

  * Create a youtube account.
  * Create a developer key here http://code.google.com/apis/youtube/dashboard.
  * sudo gem install youtube\_it


Note: youtube\_it supports ClientLogin(YouTube account), OAuth, or AuthSub authentication methods.

## Example Rails 3 App

An example of how to use youtube\_it with Rails 3 can be found [here](http://github.com/chebyte/youtube_it_rails_app_example).

## Demo

You can see youtube\_it in action [here](http://youtube-it.heroku.com).

## Establishing a Client

Important: The Account Authentication API for OAuth 1.0, AuthSub and Client Login has been officially deprecated as of April 20, 2012. It will continue to work as per our [deprecation policy](https://developers.google.com/accounts/terms), but we encourage you to migrate to OAuth 2.0 authentication as soon as possible. If you are building a new application, you should use OAuth 2.0 authentication.

####Creating a Client
```ruby
require 'youtube_it'
client = YouTubeIt::Client.new
```

####Client with Developer Key

```ruby
client = YouTubeIt::Client.new(:dev_key => "developer_key")
```

####Client with YouTube Account and Developer Key

```ruby
client = YouTubeIt::Client.new(:username => "youtube_username", :password =>  "youtube_password", :dev_key => "developer_key")
```

####Client with AuthSub

```ruby
client = YouTubeIt::AuthSubClient.new(:token => "token" , :dev_key => "developer_key")
```

####Client with OAuth

```ruby
client = YouTubeIt::OAuthClient.new("consumer_key", "consumer_secret", "youtube_username", "developer_key")
client.authorize_from_access("access_token", "access_secret")
```

####Client with OAuth2

```ruby
client = YouTubeIt::OAuth2Client.new(client_access_token: "access_token", client_refresh_token: "refresh_token", client_id: "client_id", client_secret: "client_secret", dev_key: "dev_key", expires_at: "expiration time")
```

If your access token is still valid (be careful, access tokens may only be valid for about 1 hour), you can use the client directly. Refreshing the token is simple:

```ruby
client.refresh_access_token!
```

You can see more about OAuth2 in the [wiki]( https://github.com/kylejginavan/youtube_it/wiki/How-To:-Use-OAuth-2).

## Profiles

You can use multiple profiles in the same account:

```ruby
profiles = client.profiles(['username1','username2']) 
profiles['username1'].username, "username1"
```

## Video Queries

Note:  Each type of client enables searching capabilities.

###Basic Queries

```ruby
client.videos_by(:query => "penguin")
client.videos_by(:query => "penguin", :page => 2, :per_page => 15)
client.videos_by(:query => "penguin", :restriction => "DE")
client.videos_by(:tags => ['tiger', 'leopard'])
client.videos_by(:categories => [:news, :sports])
client.videos_by(:categories => [:news, :sports], :tags => ['soccer', 'football'])
client.videos_by(:user => 'liz')
client.videos_by(:favorites, :user => 'liz')
client.video_by("FQK1URcxmb4")
client.video_by("https://www.youtube.com/watch?v=QsbmrCtiEUU")  
client.video_by_user("chebyte","FQK1URcxmb4")
```

###Standard Queries

```ruby
client.videos_by(:most_viewed)
client.videos_by(:most_linked, :page => 3)
client.videos_by(:top_rated, :time => :today)
```

###Advanced Queries (with boolean operators OR (either), AND (include), NOT (exclude))

```ruby
client.videos_by(:categories => { :either => [:news, :sports], :exclude => [:comedy] }, :tags => { :include => ['football'], :exclude => ['soccer'] })
```


###Custom Query Params

```ruby
client.videos_by(:query => "penguin", :safe_search => "strict")
client.videos_by(:query => "penguin", :duration => "long")
client.videos_by(:query => "penguin", :hd => "true")
client.videos_by(:query => "penguin", :region => "AR")
```

You can see more options [here](https://developers.google.com/youtube/2.0/reference#yt_format).

####Fields Parameter(experimental features):
Return videos more than 1000 views:

```ruby
client.videos_by(:fields => {:view_count => "1000"})
```

####Filter by date

```ruby
client.videos_by(:fields => {:published  => ((Date.today)})
client.videos_by(:fields => {:recorded   => ((Date.today)})  
```

####Filter by date with range

```ruby
client.videos_by(:fields => {:published  => ((Date.today - 30)..(Date.today))})
client.videos_by(:fields => {:recorded   => ((Date.today - 30)..(Date.today))})  
```

Note: These queries do not find private videos! Use these methods instead:
```ruby
client.get_my_video("FQK1URcxmb4")
client.get_my_videos(:query => "penguin")
```

##Video Management

Note: YouTube account, OAuth, or AuthSub enables video management.

####Upload Video

```ruby
client.video_upload(File.open("test.mov"), :title => "test",:description => 'some description', :category => 'People',:keywords => %w[cool blah test])
```

####Upload Video With a Developer Tag

Note: the tags are not immediately available

```ruby
client.video_upload(File.open("test.mov"), :title => "test",:description => 'some description', :category => 'People',:keywords => %w[cool blah test], :dev_tag => 'tagdev')
```

####Upload Private Video

```ruby
client.video_upload(File.open("test.mov"), :title => "test",:description => 'some description', :category => 'People',:keywords => %w[cool blah test], :private => true)
```

####Update Video

```ruby
client.video_update("FQK1URcxmb4", :title => "new test",:description => 'new description', :category => 'People',:keywords => %w[cool blah test])
```

####Delete Video

```ruby
client.video_delete("FQK1URcxmb4")
```

####My Videos

```ruby
client.my_videos
```

####My Video

```ruby
client.my_video(video_id)
```

####Profile Details

```ruby
client.profile(user) #default: current user
```

####List Comments

```ruby
client.comments(video_id)
```

####Add a Comment

```ruby
client.add_comment(video_id, "test comment!")
```

####Add a Reply Comment

```ruby
client.add_comment(video_id, "test reply!", :reply_to => another_comment)
```

####Delete a Comment

```ruby
client.delete_comment(video_id, comment_id)
```

####List Favorites

```ruby
client.favorites(user) # default: current user
```

####Add Favorite

```ruby
client.add_favorite(video_id)
```

####Delete Favorite

```ruby
client.delete_favorite(favorite_entry_id)
```

####Like a Video

```ruby
client.like_video(video_id)
```

####Dislike a Video

```ruby
client.dislike_video(video_id)
```

####List Subscriptions

```ruby
client.subscriptions(user) # default: current user
```

####Subscribe to a Channel

```ruby
client.subscribe_channel(channel_name)
```

####Unsubscribe from a Channel

```ruby
client.unsubscribe_channel(subscription_id)
```

####List New Subscription Videos

```ruby
client.new_subscription_videos(user) # default: current user
```

####List Playlists

```ruby
client.playlists(user, order_by) # default: current user, position
```

For example, you can get the videos of your playlist ordered by title

```ruby
client.playlists(user, "title")
```

You can see more about options for order\_by [here](https://developers.google.com/youtube/2.0/reference#orderbysp).

####Select a Playlist

```ruby
client.playlist(playlist_id)
```

####Select All Videos from a Playlist

```ruby
playlist = client.playlist(playlist_id)
playlist.videos
```

####Create a Playlist

```ruby
playlist = client.add_playlist(:title => "new playlist", :description => "playlist description")
```

####Delete a Playlist

```ruby
client.delete_playlist(playlist_id)
```

####Add Video to a Playlist

```ruby
client.add_video_to_playlist(playlist_id, video_id)
```

####Remove Video from a Playlist

```ruby
client.delete_video_from_playlist(playlist_id, playlist_entry_id)
```

####Select All Videos from Your Watch Later Playlist

```ruby
watch_later = client.watchlater(user) #default: current user
watch_later.videos
```

####Add Video to Watch Later Playlist

```ruby
client.add_video_to_watchlater(video_id)
```

####Remove Video from Watch Later Playlist

```ruby
client.delete_video_from_watchlater(watchlater_entry_id)
```


####List Related Videos

```ruby
video = client.video_by("https://www.youtube.com/watch?v=QsbmrCtiEUU&feature=player_embedded")
video.related.videos
```

####Add a Response Video

```ruby
video.add_response(original_video_id, response_video_id)
```

####Delete a Response Video

```ruby
video.delete_response(original_video_id, response_video_id)
```

####List Response Videos

```ruby
video = client.video_by("https://www.youtube.com/watch?v=QsbmrCtiEUU&feature=player_embedded")
video.responses.videos
```

## Access Control List

You can give permissions in your videos, for example denied comments, rate, etc...
More info [here](http://code.google.com/apis/youtube/2.0/reference.html#youtube_data_api_tag_yt:accessControl).

You have available the followings options:

* :rate, :comment, :commentVote, :videoRespond, :list, :embed, :syndicate

with just two values:

* allowed or denied

####Example (Upload Video with Denied Comments)

```ruby
client = YouTubeIt::Client.new(:username => "youtube_username", :password =>  "youtube_password", :dev_key => "developer_key")
client.video_upload(File.open("test.mov"), :title => "test",:description => 'some description', :category => 'People',:keywords => %w[cool blah test], :comment => "denied")
```

## User Activity

You can get user activity with the followings params:

```ruby
client.activity(user) #default current user
```

## Video Upload from Browser

When uploading a video from your browser you need make a form upload with the followings params:

```ruby
upload_token(params, nexturl)
```

####Example params

```ruby
:title => "title", :description => "description", :category => "People", :tags => ["test"]
```

nexturl is the url to redirect to after upload is complete

Controller

```ruby
def upload
  @upload_info = YouTubeIt::Client.new.upload_token(params, videos_url)
end
```

View (upload.html.erb)

```erb
<% form_tag @upload_info[:url], :multipart => true do %>
  <%= hidden_field_tag :token, @upload_info[:token] %>
  <%= label_tag :file %>
  <%= file_field_tag :file %>
  <%= submit_tag "Upload video" %>
<% end %>
```

## Widescreen Video

If the video has support for widescreen

```ruby
video.embed_html_with_width(1280)
```

Note: you can specify width or just use the default of 1280.

## Using HTML5

Now you can embed videos without Flash using HTML5. Useful for mobile devices that do not support Flash.

You can specify these options:

```ruby
video.embed_html5({:class => 'video-player', :id => 'my-video', :width => '425', :height => '350', :frameborder => '1', :url_params => {:option_one => "value", :option_two => "value"}})
```

or just use with default options:

```ruby
video.embed_html5 #default: width: 425, height: 350, frameborder: 0
```

## Logging

youtube\_it passes all logs through the logger variable on the class itself. In Rails context, assign the Rails logger to that variable to collect the messages (don't forget to set the level to debug)

```ruby
YouTubeIt.logger = RAILS_DEFAULT_LOGGER
RAILS_DEFAULT_LOGGER.level = Logger::DEBUG
```

## Contributors

* Kyle J. Ginavan.
* Mauro Torres - http://github.com/chebyte
* Marko Seppa  - https://github.com/mseppae
* Walter Korman - https://github.com/shaper
* Shane Vitarana - https://github.com/shanev

## License

MIT License

Copyright (c) 2010 Kyle J. Ginavan

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
