# encoding: UTF-8

class YouTubeIt
  module Parser #:nodoc:
    class FeedParser #:nodoc:
      def initialize(content)
        @content = (content =~ URI::regexp(%w(http https)) ? open(content).read : content)

      rescue OpenURI::HTTPError => e
        raise OpenURI::HTTPError.new(e.io.status[0],e)
      rescue
        @content = content

      end

      def parse
        parse_content @content
      end

      def parse_videos
        doc = REXML::Document.new(@content)
        videos = []
        doc.elements.each("*/entry") do |video|
          videos << parse_entry(video)
        end
        videos
      end

      def remove_bom str
        str.gsub /\xEF\xBB\xBF|ï»¿/, ''
      end
    end

    class CommentsFeedParser < FeedParser #:nodoc:
      # return array of comments
      def parse_content(content)
        doc = REXML::Document.new(content.body)
        feed = doc.elements["feed"]

        comments = []
        feed.elements.each("entry") do |entry|
          comments << parse_entry(entry)
        end
        return comments
      end

      protected
        def parse_entry(entry)
          author = YouTubeIt::Model::Author.new(
            :name => (entry.elements["author"].elements["name"].text rescue nil),
            :uri  => (entry.elements["author"].elements["uri"].text rescue nil)
          )
          YouTubeIt::Model::Comment.new(
            :author    => author,
            :content   => remove_bom(entry.elements["content"].text),
            :published => entry.elements["published"].text,
            :title     => remove_bom(entry.elements["title"].text),
            :updated   => entry.elements["updated "].text,
            :url       => entry.elements["id"].text,
            :reply_to  => parse_reply(entry)
          )
        end

        def parse_reply(entry)
          if link = entry.elements["link[@rel='http://gdata.youtube.com/schemas/2007#in-reply-to']"]
            link.attributes["href"].split('/').last.gsub(/\?client.*/, '')
          end
        end
    end

    class PlaylistFeedParser < FeedParser #:nodoc:

      def parse_content(content)
        xml = REXML::Document.new(content.body)
        entry = xml.elements["entry"] || xml.elements["feed"]

        YouTubeIt::Model::Playlist.new(
          :title         => entry.elements["title"] && entry.elements["title"].text,
          :summary       => ((entry.elements["summary"] || entry.elements["media:group"].elements["media:description"]).text rescue nil),
          :description   => ((entry.elements["summary"] || entry.elements["media:group"].elements["media:description"]).text rescue nil),
          :playlist_id   => (entry.elements["id"].text[/playlist([^<]+)/, 1].sub(':','') rescue nil),
          :published     => entry.elements["published"] ? entry.elements["published"].text : nil,
          :response_code => content.status,
          :xml           => content.body)
      end
    end

    class PlaylistsFeedParser < FeedParser #:nodoc:

      # return array of playlist objects
      def parse_content(content)
        doc = REXML::Document.new(content.body)
        feed = doc.elements["feed"]

        playlists = []
        feed.elements.each("entry") do |entry|
          playlists << parse_entry(entry)
        end
        return playlists
      end

      protected

      def parse_entry(entry)
        YouTubeIt::Model::Playlist.new(
          :title         => entry.elements["title"].text,
          :summary       => (entry.elements["summary"] || entry.elements["media:group"].elements["media:description"]).text,
          :description   => (entry.elements["summary"] || entry.elements["media:group"].elements["media:description"]).text,
          :playlist_id   => entry.elements["id"].text[/playlist([^<]+)/, 1].sub(':',''),
          :published     => entry.elements["published"] ? entry.elements["published"].text : nil,
          :response_code => nil,
          :xml           => nil)
      end
    end

    # Returns an array of the user's activity
    class ActivityParser < FeedParser
      def parse_content(content)
        doc = REXML::Document.new(content.body)
        feed = doc.elements["feed"]

        activity = []
        feed.elements.each("entry") do |entry|
          parsed_activity = parse_activity(entry)
          if parsed_activity
            activity << parsed_activity
          end
        end

        return activity
      end

      protected

      # Parses the user's activity feed.
      def parse_activity(entry)
        # Figure out what kind of activity we have
        video_type = nil
        parsed_activity = nil
        entry.elements.each("category") do |category_tag|
          if category_tag.attributes["scheme"]=="http://gdata.youtube.com/schemas/2007/userevents.cat"
            video_type = category_tag.attributes["term"]
          end
        end

        if video_type
          case video_type
          when "video_rated"
            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "video_rated",
              :time => entry.elements["updated"] ? entry.elements["updated"].text : nil,
              :author => entry.elements["author"].elements["name"] ? entry.elements["author"].elements["name"].text : nil,
              :videos => parse_activity_videos(entry),
              :video_id => entry.elements["yt:videoid"] ? entry.elements["yt:videoid"].text : nil
            )
          when "video_shared"
            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "video_shared",
              :time => entry.elements["updated"] ? entry.elements["updated"].text : nil,
              :author => entry.elements["author"].elements["name"] ? entry.elements["author"].elements["name"].text : nil,
              :videos => parse_activity_videos(entry),
              :video_id => entry.elements["yt:videoid"] ? entry.elements["yt:videoid"].text : nil
            )
          when "video_favorited"
            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "video_favorited",
              :time => entry.elements["updated"] ? entry.elements["updated"].text : nil,
              :author => entry.elements["author"].elements["name"] ? entry.elements["author"].elements["name"].text : nil,
              :videos => parse_activity_videos(entry),
              :video_id => entry.elements["yt:videoid"] ? entry.elements["yt:videoid"].text : nil
            )
          when "video_commented"
            # Load the comment and video URL
            comment_thread_url = nil
            video_url = nil
            entry.elements.each("link") do |link_tag|
              case link_tag.attributes["rel"]
              when "http://gdata.youtube.com/schemas/2007#comments"
                comment_thread_url = link_tag.attributes["href"]
              when "http://gdata.youtube.com/schemas/2007#video"
                video_url = link_tag.attributes["href"]
              else
                # Invalid rel type, do nothing
              end
            end

            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "video_commented",
              :time => entry.elements["updated"] ? entry.elements["updated"].text : nil,
              :author => entry.elements["author"].elements["name"] ? entry.elements["author"].elements["name"].text : nil,
              :videos => parse_activity_videos(entry),
              :video_id => entry.elements["yt:videoid"] ? entry.elements["yt:videoid"].text : nil,
              :comment_thread_url => comment_thread_url,
              :video_url => video_url
            )
          when "video_uploaded"
            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "video_uploaded",
              :time => entry.elements["updated"] ? entry.elements["updated"].text : nil,
              :author => entry.elements["author"].elements["name"] ? entry.elements["author"].elements["name"].text : nil,
              :videos => parse_activity_videos(entry),
              :video_id => entry.elements["yt:videoid"] ? entry.elements["yt:videoid"].text : nil
            )
          when "friend_added"
            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "friend_added",
              :time => entry.elements["updated"] ? entry.elements["updated"].text : nil,
              :author => entry.elements["author"].elements["name"] ? entry.elements["author"].elements["name"].text : nil,
              :username => entry.elements["yt:username"] ? entry.elements["yt:username"].text : nil
            )
          when "user_subscription_added"
            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "user_subscription_added",
              :time => entry.elements["updated"] ? entry.elements["updated"].text : nil,
              :author => entry.elements["author"].elements["name"] ? entry.elements["author"].elements["name"].text : nil,
              :username => entry.elements["yt:username"] ? entry.elements["yt:username"].text : nil
            )
          else
            # Invalid activity type, just let it return nil
          end
        end

        return parsed_activity
      end

      # If a user enabled inline attribute videos may be included in results.
      def parse_activity_videos(entry)
        videos = []

        entry.elements.each("link") do |link_tag|
          videos << YouTubeIt::Parser::VideoFeedParser.new(link_tag).parse if link_tag.elements["entry"]
        end

        if videos.size <= 0
          videos = nil
        end

        return videos
      end
    end

    # Returns an array of the user's contacts
    class ContactsParser < FeedParser
      def parse_content(content)
        doc = REXML::Document.new(content.body)
        feed = doc.elements["feed"]

        contacts = []
        feed.elements.each("entry") do |entry|
          temp_contact = YouTubeIt::Model::Contact.new(
            :title    => entry.elements["title"] ? entry.elements["title"].text : nil,
            :username => entry.elements["yt:username"] ? entry.elements["yt:username"].text : nil,
            :status   => entry.elements["yt:status"] ? entry.elements["yt:status"].text : nil
          )

          contacts << temp_contact
        end

        return contacts
      end
    end

    # Returns an array of the user's messages
    class MessagesParser < FeedParser
      def parse_content(content)
        doc = REXML::Document.new(content.body)
        puts content.body
        puts "doc..."
        puts doc.inspect
        feed = doc.elements["feed"]

        messages = []
        feed.elements.each("entry") do |entry|
          author = entry.elements["author"]
          temp_message = YouTubeIt::Model::Message.new(
            :id  => entry.elements["id"] ? entry.elements["id"].text.gsub(/.+:inbox:/, "") : nil,
            :title    => entry.elements["title"] ? entry.elements["title"].text : nil,
            :name => author && author.elements["name"] ? author.elements["name"].text : nil,
            :summary   => entry.elements["summary"] ? entry.elements["summary"].text : nil,
            :published   => entry.elements["published"] ? entry.elements["published"].text : nil
          )

          messages << temp_message
        end

        return messages
      end
    end

    class ProfileFeedParser < FeedParser #:nodoc:
      def parse_content(content)
        xml = REXML::Document.new(content.body)
        entry = xml.elements["entry"] || xml.elements["feed"]
        parse_entry( entry )
      end
      def parse_entry(entry)
        YouTubeIt::Model::User.new(
          :age            => entry.elements["yt:age"] ? entry.elements["yt:age"].text : nil,
          :username       => entry.elements["yt:username"] ? entry.elements["yt:username"].text : nil,
          :username_display => (entry.elements["yt:username"].attributes['yt:display'] rescue nil),
          :user_id        => (entry.elements["author/yt:userId"].text rescue nil),
          :last_name      => (entry.elements["yt:lastName"].text rescue nil),
          :first_name     => (entry.elements["yt:firstName"].text rescue nil),
          :company        => entry.elements["yt:company"] ? entry.elements["yt:company"].text : nil,
          :gender         => entry.elements["yt:gender"] ? entry.elements["yt:gender"].text : nil,
          :hobbies        => entry.elements["yt:hobbies"] ? entry.elements["yt:hobbies"].text : nil,
          :hometown       => entry.elements["yt:hometown"] ? entry.elements["yt:hometown"].text : nil,
          :location       => entry.elements["yt:location"] ? entry.elements["yt:location"].text : nil,
          :last_login     => entry.elements["yt:statistics"].attributes["lastWebAccess"],
          :join_date      => entry.elements["published"] ? entry.elements["published"].text : nil,
          :movies         => entry.elements["yt:movies"] ? entry.elements["yt:movies"].text : nil,
          :music          => entry.elements["yt:music"] ? entry.elements["yt:music"].text : nil,
          :occupation     => entry.elements["yt:occupation"] ? entry.elements["yt:occupation"].text : nil,
          :relationship   => entry.elements["yt:relationship"] ? entry.elements["yt:relationship"].text : nil,
          :school         => entry.elements["yt:school"] ? entry.elements["yt:school"].text : nil,
          :avatar         => entry.elements["media:thumbnail"] ? entry.elements["media:thumbnail"].attributes["url"] : nil,
          :upload_count   => (entry.elements['gd:feedLink[attribute::rel="http://gdata.youtube.com/schemas/2007#user.uploads"]'].attributes['countHint'] rescue nil),
          :max_upload_duration => (entry.elements["yt:maxUploadDuration"].attributes['seconds'].to_i rescue nil),
          :subscribers    => entry.elements["yt:statistics"].attributes["subscriberCount"],
          :videos_watched => entry.elements["yt:statistics"].attributes["videoWatchCount"],
          :view_count     => entry.elements["yt:statistics"].attributes["viewCount"],
          :upload_views   => entry.elements["yt:statistics"].attributes["totalUploadViews"],
          :insight_uri    => (entry.elements['link[attribute::rel="http://gdata.youtube.com/schemas/2007#insight.views"]'].attributes['href'] rescue nil)
        )
      end
    end

    class BatchProfileFeedParser < ProfileFeedParser
      def parse_content(content)
        doc = REXML::Document.new(content.body).elements.to_a("*/entry").map do |entry|
          username = entry.get_text('./batch:id').to_s
          result = catch(:result) do
            case entry.elements['./batch:status'].attribute('code').to_s.to_i
            when 200...300 then parse_entry( entry )
            else nil
            end
          end
          { username => result }
        end.reduce({},:merge)
      end
    end

    class SubscriptionFeedParser < FeedParser #:nodoc:

      def parse_content(content)
        doc = REXML::Document.new(content.body)
        feed = doc.elements["feed"]

        subscriptions = []
        feed.elements.each("entry") do |entry|
          subscriptions << parse_entry(entry)
        end
        return subscriptions
      end

      protected

      def parse_entry(entry)
        YouTubeIt::Model::Subscription.new(
          :title        => entry.elements["title"].text,
          :id           => entry.elements["id"].text[/subscription([^<]+)/, 1].sub(':',''),
          :published    => entry.elements["published"] ? entry.elements["published"].text : nil
        )
      end
    end


    class VideoFeedParser < FeedParser #:nodoc:

      def parse_content(content)
        doc = (content.is_a?(REXML::Element)) ? content : REXML::Document.new(content)

        entry = doc.elements["entry"]
        parse_entry(entry)
      end

      protected
      def parse_entry(entry)
        video_id = entry.elements["id"].text
        published_at  = entry.elements["published"] ? Time.parse(entry.elements["published"].text) :
          entry.elements["media:group"].elements["yt:uploaded"] ? Time.parse(entry.elements["media:group"].elements["yt:uploaded"].text) :
          nil
        updated_at    = entry.elements["updated"] ? Time.parse(entry.elements["updated"].text) : nil

        # parse the category and keyword lists
        categories = []
        keywords = []
        entry.elements.each("category") do |category|
          # determine if  it's really a category, or just a keyword
          scheme = category.attributes["scheme"]
          if (scheme =~ /\/categories\.cat$/)
            # it's a category
            categories << YouTubeIt::Model::Category.new(
                            :term => category.attributes["term"],
                            :label => category.attributes["label"])

          elsif (scheme =~ /\/keywords\.cat$/)
            # it's a keyword
            keywords << category.attributes["term"]
          end
        end

        title = entry.elements["title"].text
        html_content = entry.elements["content"] ? entry.elements["content"].text : nil

        # parse the author
        author_element = entry.elements["author"]
        author = nil
        if author_element
          author = YouTubeIt::Model::Author.new(
                     :name => author_element.elements["name"].text,
                     :uri => author_element.elements["uri"].text)
        end
        media_group = entry.elements["media:group"]

        ytid = nil
        unless media_group.elements["yt:videoid"].nil?
          ytid = media_group.elements["yt:videoid"].text
        end

        # if content is not available on certain region, there is no media:description, media:player or yt:duration
        description = ""
        unless media_group.elements["media:description"].nil?
          description = media_group.elements["media:description"].text
        end

        # if content is not available on certain region, there is no media:description, media:player or yt:duration
        duration = 0
        unless media_group.elements["yt:duration"].nil?
          duration = media_group.elements["yt:duration"].attributes["seconds"].to_i
        end

        # if content is not available on certain region, there is no media:description, media:player or yt:duration
        player_url = ""
        unless media_group.elements["media:player"].nil?
          player_url = media_group.elements["media:player"].attributes["url"]
        end

        unless media_group.elements["yt:aspectRatio"].nil?
          widescreen = media_group.elements["yt:aspectRatio"].text == 'widescreen' ? true : false
        end

        media_content = []
        media_group.elements.each("media:content") do |mce|
          media_content << parse_media_content(mce)
        end

        # parse thumbnails
        thumbnails = []
        media_group.elements.each("media:thumbnail") do |thumb_element|
          # TODO: convert time HH:MM:ss string to seconds?
          thumbnails << YouTubeIt::Model::Thumbnail.new(
                          :url    => thumb_element.attributes["url"],
                          :height => thumb_element.attributes["height"].to_i,
                          :width  => thumb_element.attributes["width"].to_i,
                          :time   => thumb_element.attributes["time"])
        end

        rating_element = entry.elements["gd:rating"]
        extended_rating_element = entry.elements["yt:rating"]

        rating = nil
        if rating_element
          rating_values = {
            :min         => rating_element.attributes["min"].to_i,
            :max         => rating_element.attributes["max"].to_i,
            :rater_count => rating_element.attributes["numRaters"].to_i,
            :average     => rating_element.attributes["average"].to_f
          }

          if extended_rating_element
            rating_values[:likes] = extended_rating_element.attributes["numLikes"].to_i
            rating_values[:dislikes] = extended_rating_element.attributes["numDislikes"].to_i
          end

          rating = YouTubeIt::Model::Rating.new(rating_values)
        end

        if (el = entry.elements["yt:statistics"])
          view_count, favorite_count = el.attributes["viewCount"].to_i, el.attributes["favoriteCount"].to_i
        else
          view_count, favorite_count = 0,0
        end

        comment_count = ( entry.elements['./gd:comments/gd:feedLink[attribute::rel="http://gdata.youtube.com/schemas/2007#comments"]'].attributes['countHint'] rescue nil).to_i

        access_control = entry.elements.to_a('yt:accessControl').map do |e|
          { e.attributes['action'] => e.attributes['permission'] }
        end.compact.reduce({},:merge)

        noembed     = entry.elements["yt:noembed"] ? true : false
        safe_search = entry.elements["media:rating"] ? true : false

        if where = entry.elements["georss:where"]
          position = where.elements["gml:Point"].elements["gml:pos"].text
          latitude, longitude = position.split.map &:to_f
        end

        control = entry.elements["app:control"]
        state = { :name => "published" }
        if control && control.elements["yt:state"]
          state = {
            :name        => control.elements["yt:state"].attributes["name"],
            :reason_code => control.elements["yt:state"].attributes["reasonCode"],
            :help_url    => control.elements["yt:state"].attributes["helpUrl"],
            :copy        => control.elements["yt:state"].text
          }

        end

        insight_uri = (entry.elements['link[attribute::rel="http://gdata.youtube.com/schemas/2007#insight.views"]'].attributes['href'] rescue nil)

        perm_private = media_group.elements["yt:private"] ? true : false

        YouTubeIt::Model::Video.new(
          :video_id       => video_id,
          :published_at   => published_at,
          :updated_at     => updated_at,
          :categories     => categories,
          :keywords       => keywords,
          :title          => title,
          :html_content   => html_content,
          :author         => author,
          :description    => description,
          :duration       => duration,
          :media_content  => media_content,
          :player_url     => player_url,
          :thumbnails     => thumbnails,
          :rating         => rating,
          :view_count     => view_count,
          :favorite_count => favorite_count,
          :comment_count  => comment_count,
          :access_control => access_control,
          :widescreen     => widescreen,
          :noembed        => noembed,
          :safe_search    => safe_search,
          :position       => position,
          :latitude       => latitude,
          :longitude      => longitude,
          :state          => state,
          :insight_uri    => insight_uri,
          :unique_id      => ytid,
          :perm_private   => perm_private)
      end

      def parse_media_content (media_content_element)
        content_url = media_content_element.attributes["url"]
        format_code = media_content_element.attributes["yt:format"].to_i
        format = YouTubeIt::Model::Video::Format.by_code(format_code)
        duration = media_content_element.attributes["duration"].to_i
        mime_type = media_content_element.attributes["type"]
        default = (media_content_element.attributes["isDefault"] == "true")

        YouTubeIt::Model::Content.new(
          :url       => content_url,
          :format    => format,
          :duration  => duration,
          :mime_type => mime_type,
          :default   => default)
      end
    end

    class VideosFeedParser < VideoFeedParser #:nodoc:

    private
      def parse_content(content)
        videos  = []
        doc     = REXML::Document.new(content)
        feed    = doc.elements["feed"]
        if feed
          feed_id            = feed.elements["id"].text
          updated_at         = Time.parse(feed.elements["updated"].text)
          total_result_count = feed.elements["openSearch:totalResults"].text.to_i
          offset             = feed.elements["openSearch:startIndex"].text.to_i
          max_result_count   = feed.elements["openSearch:itemsPerPage"].text.to_i

          feed.elements.each("entry") do |entry|
            videos << parse_entry(entry)
          end
        end
        YouTubeIt::Response::VideoSearch.new(
          :feed_id            => feed_id || nil,
          :updated_at         => updated_at || nil,
          :total_result_count => total_result_count || nil,
          :offset             => offset || nil,
          :max_result_count   => max_result_count || nil,
          :videos             => videos)
      end
    end
  end
end

