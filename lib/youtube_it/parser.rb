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

      def parse_single_entry
        doc = Nokogiri::XML(@content)
        parse_entry(doc.at("entry") || doc)
      end

      def parse_videos
        doc = Nokogiri::XML(@content)
        videos = []
        doc.css("entry").each do |video|
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
        doc = Nokogiri::XML(content.body)
        feed = doc.at("feed")

        comments = []
        feed.css("entry").each do |entry|
          comments << parse_entry(entry)
        end
        return comments
      end

      protected
        def parse_entry(entry)
          author = YouTubeIt::Model::Author.new(
            :name => (entry.at("author/name").text rescue nil),
            :uri  => (entry.at("author/uri").text rescue nil)
          )
          YouTubeIt::Model::Comment.new(
            :author    => author,
            :content   => remove_bom(entry.at("content").text),
            :published => entry.at("published").text,
            :title     => remove_bom(entry.at("title").text),
            :updated   => entry.at("updated").text,
            :url       => entry.at("id").text,
            :reply_to  => parse_reply(entry)
          )
        end

        def parse_reply(entry)
          if link = entry.at_xpath("xmlns:link[@rel='http://gdata.youtube.com/schemas/2007#in-reply-to']")
            link["href"].split('/').last.gsub(/\?client.*/, '')
          end
        end
    end

    class PlaylistFeedParser < FeedParser #:nodoc:

      def parse_content(content)
        xml = Nokogiri::XML(content.body)
        entry = xml.at("feed") || xml.at("entry")
        YouTubeIt::Model::Playlist.new(
          :title         => entry.at("title") && entry.at("title").text,
          :summary       => ((entry.at("summary") || entry.at_xpath("media:group").at_xpath("media:description")).text rescue nil),
          :description   => ((entry.at("summary") || entry.at_xpath("media:group").at_xpath("media:description")).text rescue nil),
          :playlist_id   => (entry.at("id").text[/playlist:(\w+)/, 1] rescue nil),
          :published     => entry.at("published") ? entry.at("published").text : nil,
          :response_code => content.status,
          :xml           => content.body)
      end
    end

    class PlaylistsFeedParser < FeedParser #:nodoc:

      # return array of playlist objects
      def parse_content(content)
        doc = Nokogiri::XML(content.body)
        feed = doc.at("feed")

        playlists = []
        feed.css("entry").each do |entry|
          playlists << parse_entry(entry)
        end
        return playlists
      end

      protected

      def parse_entry(entry)
        YouTubeIt::Model::Playlist.new(
          :title         => entry.at("title").text,
          :summary       => (entry.at("summary") || entry.at_xpath("media:group").at_xpath("media:description")).text,
          :description   => (entry.at("summary") || entry.at_xpath("media:group").at_xpath("media:description")).text,
          :playlist_id   => entry.at("id").text[/playlist([^<]+)/, 1].sub(':',''),
          :published     => entry.at("published") ? entry.at("published").text : nil,
          :response_code => nil,
          :xml           => nil)
      end
    end

    # Returns an array of the user's activity
    class ActivityParser < FeedParser
      def parse_content(content)
        doc = Nokogiri::XML(content.body)
        feed = doc.at("feed")

        activities = []
        feed.css("entry").each do |entry|
          if parsed_activity = parse_activity(entry)
            activities << parsed_activity
          end
        end

        return activities
      end

      protected

      # Parses the user's activity feed.
      def parse_activity(entry)
        # Figure out what kind of activity we have
        video_type = nil
        parsed_activity = nil
        entry.css("category").each do |category_tag|
          if category_tag["scheme"] == "http://gdata.youtube.com/schemas/2007/userevents.cat"
            video_type = category_tag["term"]
          end
        end

        if video_type
          case video_type
          when "video_rated"
            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "video_rated",
              :time => entry.at("updated") ? entry.at("updated").text : nil,
              :author => entry.at("author/name") ? entry.at("author/name").text : nil,
              :videos => parse_activity_videos(entry),
              :video_id => entry.at_xpath("yt:videoid") ? entry.at_xpath("yt:videoid").text : nil
            )
          when "video_shared"
            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "video_shared",
              :time => entry.at("updated") ? entry.at("updated").text : nil,
              :author => entry.at("author/name") ? entry.at("author/name").text : nil,
              :videos => parse_activity_videos(entry),
              :video_id => entry.at_xpath("yt:videoid") ? entry.at_xpath("yt:videoid").text : nil
            )
          when "video_favorited"
            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "video_favorited",
              :time => entry.at("updated") ? entry.at("updated").text : nil,
              :author => entry.at("author/name") ? entry.at("author/name").text : nil,
              :videos => parse_activity_videos(entry),
              :video_id => entry.at_xpath("yt:videoid") ? entry.at_xpath("yt:videoid").text : nil
            )
          when "video_commented"
            # Load the comment and video URL
            comment_thread_url = nil
            video_url = nil
            entry.css("link").each do |link_tag|
              case link_tag["rel"]
              when "http://gdata.youtube.com/schemas/2007#comments"
                comment_thread_url = link_tag["href"]
              when "http://gdata.youtube.com/schemas/2007#video"
                video_url = link_tag["href"]
              else
                # Invalid rel type, do nothing
              end
            end

            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "video_commented",
              :time => entry.at("updated") ? entry.at("updated").text : nil,
              :author => entry.at("author/name") ? entry.at("author/name").text : nil,
              :videos => parse_activity_videos(entry),
              :video_id => entry.at_xpath("yt:videoid") ? entry.at_xpath("yt:videoid").text : nil,
              :comment_thread_url => comment_thread_url,
              :video_url => video_url
            )
          when "video_uploaded"
            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "video_uploaded",
              :time => entry.at("updated") ? entry.at("updated").text : nil,
              :author => entry.at("author/name") ? entry.at("author/name").text : nil,
              :videos => parse_activity_videos(entry),
              :video_id => entry.at_xpath("yt:videoid") ? entry.at_xpath("yt:videoid").text : nil
            )
          when "friend_added"
            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "friend_added",
              :time => entry.at("updated") ? entry.at("updated").text : nil,
              :author => entry.at("author/name") ? entry.at("author/name").text : nil,
              :username => entry.at_xpath("yt:username") ? entry.at_xpath("yt:username").text : nil
            )
          when "user_subscription_added"
            parsed_activity = YouTubeIt::Model::Activity.new(
              :type => "user_subscription_added",
              :time => entry.at("updated") ? entry.at("updated").text : nil,
              :author => entry.at("author/name") ? entry.at("author/name").text : nil,
              :username => entry.at_xpath("yt:username") ? entry.at_xpath("yt:username").text : nil
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

        entry.css("link").each do |link_tag|
          videos << YouTubeIt::Parser::VideoFeedParser.new(link_tag).parse if link_tag.at("entry")
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
        doc = Nokogiri::XML(content.body)
        feed = doc.at("feed")

        contacts = []
        feed.css("entry").each do |entry|
          temp_contact = YouTubeIt::Model::Contact.new(
            :title    => entry.at("title") ? entry.at("title").text : nil,
            :username => entry.at_xpath("yt:username") ? entry.at_xpath("yt:username").text : nil,
            :status   => entry.at_xpath("yt:status") ? entry.at_xpath("yt:status").text : nil
          )

          contacts << temp_contact
        end

        return contacts
      end
    end

    # Returns an array of the user's messages
    class MessagesParser < FeedParser
      def parse_content(content)
        doc = Nokogiri::XML(content.body)
        feed = doc.at("feed")

        messages = []
        feed.css("entry").each do |entry|
          author = entry.at("author")
          temp_message = YouTubeIt::Model::Message.new(
            :id  => entry.at("id") ? entry.at("id").text.gsub(/.+:inbox:/, "") : nil,
            :title    => entry.at("title") ? entry.at("title").text : nil,
            :name => author && author.at("name") ? author.at("name").text : nil,
            :summary   => entry.at("summary") ? entry.at("summary").text : nil,
            :published   => entry.at("published") ? entry.at("published").text : nil
          )

          messages << temp_message
        end

        return messages
      end
    end

    class ProfileFeedParser < FeedParser #:nodoc:
      def parse_content(content)
        xml = Nokogiri::XML(content.body)
        entry = xml.at("entry") || xml.at("feed")
        parse_entry(entry)
      end
      def parse_entry(entry)
        YouTubeIt::Model::User.new(
          :age            => entry.at_xpath("yt:age") ? entry.at_xpath("yt:age").text : nil,
          :username       => entry.at_xpath("yt:username") ? entry.at_xpath("yt:username").text : nil,
          :username_display => (entry.at_xpath("yt:username")['display'] rescue nil),
          :user_id        => (entry.at_xpath("xmlns:author/yt:userId").text rescue nil),
          :last_name      => (entry.at_xpath("yt:lastName").text rescue nil),
          :first_name     => (entry.at_xpath("yt:firstName").text rescue nil),
          :company        => entry.at_xpath("yt:company") ? entry.at_xpath("yt:company").text : nil,
          :gender         => entry.at_xpath("yt:gender") ? entry.at_xpath("yt:gender").text : nil,
          :hobbies        => entry.at_xpath("yt:hobbies") ? entry.at_xpath("yt:hobbies").text : nil,
          :hometown       => entry.at_xpath("yt:hometown") ? entry.at_xpath("yt:hometown").text : nil,
          :location       => entry.at_xpath("yt:location") ? entry.at_xpath("yt:location").text : nil,
          :last_login     => entry.at_xpath("yt:statistics")["lastWebAccess"],
          :join_date      => entry.at("published") ? entry.at("published").text : nil,
          :movies         => entry.at_xpath("yt:movies") ? entry.at_xpath("yt:movies").text : nil,
          :music          => entry.at_xpath("yt:music") ? entry.at_xpath("yt:music").text : nil,
          :occupation     => entry.at_xpath("yt:occupation") ? entry.at_xpath("yt:occupation").text : nil,
          :relationship   => entry.at_xpath("yt:relationship") ? entry.at_xpath("yt:relationship").text : nil,
          :school         => entry.at_xpath("yt:school") ? entry.at_xpath("yt:school").text : nil,
          :avatar         => entry.at_xpath("media:thumbnail") ? entry.at_xpath("media:thumbnail")["url"] : nil,
          :upload_count   => (entry.at_xpath('gd:feedLink[@rel="http://gdata.youtube.com/schemas/2007#user.uploads"]')['countHint'].to_i rescue nil),
          :max_upload_duration => (entry.at_xpath("yt:maxUploadDuration")['seconds'].to_i rescue nil),
          :subscribers    => entry.at_xpath("yt:statistics")["subscriberCount"],
          :videos_watched => entry.at_xpath("yt:statistics")["videoWatchCount"],
          :view_count     => entry.at_xpath("yt:statistics")["viewCount"],
          :upload_views   => entry.at_xpath("yt:statistics")["totalUploadViews"],
          :insight_uri    => (entry.at_xpath('xmlns:link[@rel="http://gdata.youtube.com/schemas/2007#insight.views"]')['href'] rescue nil)
        )
      end
    end

    class BatchProfileFeedParser < ProfileFeedParser
      def parse_content(content)
        Nokogiri::XML(content.body).xpath("//xmlns:entry").map do |entry|
          entry.namespaces.each {|name, url| entry.document.root.add_namespace name, url }
          username = entry.at_xpath('batch:id', entry.namespaces).text
          result = catch(:result) do
            case entry.at_xpath('batch:status', entry.namespaces)['code'].to_i
            when 200...300 then parse_entry(entry)
            else nil
            end
          end
          { username => result }
        end.reduce({},:merge)
      end
    end

    class SubscriptionFeedParser < FeedParser #:nodoc:

      def parse_content(content)
        doc = Nokogiri::XML(content.body)
        feed = doc.at("feed")

        subscriptions = []
        feed.css("entry").each do |entry|
          subscriptions << parse_entry(entry)
        end
        return subscriptions
      end

      protected

      def parse_entry(entry)
        YouTubeIt::Model::Subscription.new(
          :title        => entry.at("title").text,
          :id           => entry.at("id").text[/subscription([^<]+)/, 1].sub(':',''),
          :published    => entry.at("published") ? entry.at("published").text : nil
        )
      end
    end

    class CaptionFeedParser < FeedParser #:nodoc:

      def parse_content(content)
        doc = (content.is_a?(Nokogiri::XML::Document)) ? content : Nokogiri::XML(content)

        entry = doc.at "entry"
        parse_entry(entry)
      end

      protected

      def parse_entry(entry)
        YouTubeIt::Model::Caption.new(
            :title        => entry.at("title").text,
            :id           => entry.at("id").text[/captions([^<]+)/, 1].sub(':',''),
            :published    => entry.at("published") ? entry.at("published").text : nil
        )
      end
    end

    class VideoFeedParser < FeedParser #:nodoc:

      def parse_content(content)
        doc = (content.is_a?(Nokogiri::XML::Document)) ? content : Nokogiri::XML(content)

        entry = doc.at "entry"
        parse_entry(entry)
      end

      protected
      def parse_entry(entry)
        video_id = entry.at("id").text
        published_at = entry.at("published") ? Time.parse(entry.at("published").text) : nil
        uploaded_at = entry.at_xpath("media:group/yt:uploaded") ? Time.parse(entry.at_xpath("media:group/yt:uploaded").text) : nil
        updated_at = entry.at("updated") ? Time.parse(entry.at("updated").text) : nil
        recorded_at = entry.at_xpath("yt:recorded") ? Time.parse(entry.at_xpath("yt:recorded").text) : nil

        # parse the category and keyword lists
        categories = []
        keywords = []
        entry.css("category").each do |category|
          # determine if  it's really a category, or just a keyword
          scheme = category["scheme"]
          if (scheme =~ /\/categories\.cat$/)
            # it's a category
            categories << YouTubeIt::Model::Category.new(
                            :term => category["term"],
                            :label => category["label"])

          elsif (scheme =~ /\/keywords\.cat$/)
            # it's a keyword
            keywords << category["term"]
          end
        end

        title = entry.at("title").text
        html_content = nil #entry.at("content") ? entry.at("content").text : nil

        # parse the author
        author_element = entry.at("author")
        author = nil
        if author_element
          author = YouTubeIt::Model::Author.new(
                     :name => author_element.at("name").text,
                     :uri => author_element.at("uri").text)
        end
        media_group = entry.at_xpath('media:group')

        ytid = nil
        unless media_group.at_xpath("yt:videoid").nil?
          ytid = media_group.at_xpath("yt:videoid").text
        end

        # if content is not available on certain region, there is no media:description, media:player or yt:duration
        description = ""
        unless media_group.at_xpath("media:description").nil?
          description = media_group.at_xpath("media:description").text
        end

        # if content is not available on certain region, there is no media:description, media:player or yt:duration
        duration = 0
        unless media_group.at_xpath("yt:duration").nil?
          duration = media_group.at_xpath("yt:duration")["seconds"].to_i
        end

        # if content is not available on certain region, there is no media:description, media:player or yt:duration
        player_url = ""
        unless media_group.at_xpath("media:player").nil?
          player_url = media_group.at_xpath("media:player")["url"]
        end

        unless media_group.at_xpath("yt:aspectRatio").nil?
          widescreen = media_group.at_xpath("yt:aspectRatio").text == 'widescreen' ? true : false
        end

        media_content = []
        media_group.xpath("media:content").each do |mce|
          media_content << parse_media_content(mce)
        end

        # parse thumbnails
        thumbnails = []
        media_group.xpath("media:thumbnail").each do |thumb_element|
          # TODO: convert time HH:MM:ss string to seconds?
          thumbnails << YouTubeIt::Model::Thumbnail.new(
                          :url    => thumb_element["url"],
                          :height => thumb_element["height"].to_i,
                          :width  => thumb_element["width"].to_i,
                          :time   => thumb_element["time"])
        end

        rating_element = entry.at_xpath("gd:rating")
        extended_rating_element = entry.at_xpath("yt:rating")

        rating = nil
        if rating_element
          rating_values = {
            :min         => rating_element["min"].to_i,
            :max         => rating_element["max"].to_i,
            :rater_count => rating_element["numRaters"].to_i,
            :average     => rating_element["average"].to_f
          }

          if extended_rating_element
            rating_values[:likes] = extended_rating_element["numLikes"].to_i
            rating_values[:dislikes] = extended_rating_element["numDislikes"].to_i
          end

          rating = YouTubeIt::Model::Rating.new(rating_values)
        end

        if (el = entry.at_xpath("yt:statistics"))
          view_count, favorite_count = el["viewCount"].to_i, el["favoriteCount"].to_i
        else
          view_count, favorite_count = 0,0
        end

        comment_feed = entry.at_xpath('gd:comments/gd:feedLink[@rel="http://gdata.youtube.com/schemas/2007#comments"]')
        comment_count = comment_feed ? comment_feed['countHint'].to_i : 0

        access_control = entry.xpath('yt:accessControl').map do |e|
          { e['action'] => e['permission'] }
        end.compact.reduce({},:merge)

        noembed     = entry.at_xpath("yt:noembed") ? true : false
        safe_search = entry.at_xpath("media:rating") ? true : false

        if entry.namespaces['xmlns:georss'] and where = entry.at_xpath("georss:where")
          position = where.at_xpath("gml:Point").at_xpath("gml:pos").text
          latitude, longitude = position.split.map &:to_f
        end

        if entry.namespaces['xmlns:app']
          control = entry.at_xpath("app:control")
          state = { :name => "published" }
          if control && control.at_xpath("yt:state")
            state = {
              :name        => control.at_xpath("yt:state")["name"],
              :reason_code => control.at_xpath("yt:state")["reasonCode"],
              :help_url    => control.at_xpath("yt:state")["helpUrl"],
              :copy        => control.at_xpath("yt:state").text
            }
          end
        end

        insight_uri = (entry.at_xpath('xmlns:link[@rel="http://gdata.youtube.com/schemas/2007#insight.views"]')['href'] rescue nil)

        perm_private = media_group.at_xpath("yt:private") ? true : false

        YouTubeIt::Model::Video.new(
          :video_id       => video_id,
          :published_at   => published_at,
          :updated_at     => updated_at,
          :uploaded_at    => uploaded_at,
          :recorded_at    => recorded_at,
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

      def parse_media_content (elem)
        content_url = elem["url"]
        format_code = elem["format"].to_i
        format = YouTubeIt::Model::Video::Format.by_code(format_code)
        duration = elem["duration"].to_i
        mime_type = elem["type"]
        default = (elem["isDefault"] == "true")

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
        doc     = Nokogiri::XML(content)
        feed    = doc.at "feed"
        if feed
          feed_id            = feed.at("id").text
          updated_at         = Time.parse(feed.at("updated").text)
          total_result_count = feed.at_xpath("openSearch:totalResults").text.to_i
          offset             = feed.at_xpath("openSearch:startIndex").text.to_i
          max_result_count   = feed.at_xpath("openSearch:itemsPerPage").text.to_i

          feed.css("entry").each do |entry|
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

