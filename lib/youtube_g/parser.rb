class YouTubeG
  module Parser #:nodoc:
    class FeedParser #:nodoc:
      def initialize(url)
        @url = url
      end
      
      def parse
        parse_content open(@url).read
      end      
    end

    class VideoFeedParser < FeedParser #:nodoc:
      
      def parse_content(content)
        doc = REXML::Document.new(content)
        entry = doc.elements["entry"]
        parse_entry(entry)
      end

    protected
      def parse_entry(entry) 
        video_id = entry.elements["id"].text
        published_at = Time.parse(entry.elements["published"].text)
        updated_at = Time.parse(entry.elements["updated"].text)

        # parse the category and keyword lists
        categories = []
        keywords = []
        entry.elements.each("category") do |category|
          # determine if  it's really a category, or just a keyword
          scheme = category.attributes["scheme"]
          if (scheme =~ /\/categories\.cat$/)
            # it's a category
            categories << YouTubeG::Model::Category.new(
                            :term => category.attributes["term"],
                            :label => category.attributes["label"])

          elsif (scheme =~ /\/keywords\.cat$/)
            # it's a keyword
            keywords << category.attributes["term"]
          end
        end

        title = entry.elements["title"].text
        html_content = entry.elements["content"].text

        # parse the author
        author_element = entry.elements["author"]
        author = nil
        if author_element
          author = YouTubeG::Model::Author.new(
                     :name => author_element.elements["name"].text,
                     :uri => author_element.elements["uri"].text)
        end
      
        media_group = entry.elements["media:group"]
        description = media_group.elements["media:description"].text
        duration = media_group.elements["yt:duration"].attributes["seconds"].to_i

        media_content = []
        media_group.elements.each("media:content") do |mce|
          media_content << parse_media_content(mce)
        end

        player_url = media_group.elements["media:player"].attributes["url"]

        # parse thumbnails
        thumbnails = []
        media_group.elements.each("media:thumbnail") do |thumb_element|
          # TODO: convert time HH:MM:ss string to seconds?
          thumbnails << YouTubeG::Model::Thumbnail.new(
                          :url => thumb_element.attributes["url"],
                          :height => thumb_element.attributes["height"].to_i,
                          :width => thumb_element.attributes["width"].to_i,
                          :time => thumb_element.attributes["time"])
        end

        rating_element = entry.elements["gd:rating"]
        rating = nil
        if rating_element
          rating = YouTubeG::Model::Rating.new(
                     :min => rating_element.attributes["min"].to_i,
                     :max => rating_element.attributes["max"].to_i,
                     :rater_count => rating_element.attributes["numRaters"].to_i,
                     :average => rating_element.attributes["average"].to_f)
        end

        view_count = (el = entry.elements["yt:statistics"]) ? el.attributes["viewCount"].to_i : 0

        noembed = entry.elements["yt:noembed"] ? true : false
        racy = entry.elements["media:rating"] ? true : false

        if where = entry.elements["georss:where"]
          position = where.elements["gml:Point"].elements["gml:pos"].text
          latitude, longitude = position.split(" ")
        end

        YouTubeG::Model::Video.new(
          :video_id => video_id,
          :published_at => published_at,
          :updated_at => updated_at,
          :categories => categories,
          :keywords => keywords,
          :title => title,
          :html_content => html_content,
          :author => author,
          :description => description,
          :duration => duration,
          :media_content => media_content,
          :player_url => player_url,
          :thumbnails => thumbnails,
          :rating => rating,
          :view_count => view_count,
          :noembed => noembed,
          :racy => racy,
          :where => where,
          :position => position,
          :latitude => latitude,
          :longitude => longitude)
      end

      def parse_media_content (media_content_element) 
        content_url = media_content_element.attributes["url"]
        format_code = media_content_element.attributes["yt:format"].to_i
        format = YouTubeG::Model::Video::Format.by_code(format_code)
        duration = media_content_element.attributes["duration"].to_i
        mime_type = media_content_element.attributes["type"]
        default = (media_content_element.attributes["isDefault"] == "true")

        YouTubeG::Model::Content.new(
          :url => content_url,
          :format => format,
          :duration => duration,
          :mime_type => mime_type,
          :default => default)
      end      
    end

    class VideosFeedParser < VideoFeedParser #:nodoc:

    private
      def parse_content(content) #:nodoc:
        doc = REXML::Document.new(content)
        feed = doc.elements["feed"]

        feed_id = feed.elements["id"].text
        updated_at = Time.parse(feed.elements["updated"].text)
        total_result_count = feed.elements["openSearch:totalResults"].text.to_i
        offset = feed.elements["openSearch:startIndex"].text.to_i
        max_result_count = feed.elements["openSearch:itemsPerPage"].text.to_i

        videos = []
        feed.elements.each("entry") do |entry|
          videos << parse_entry(entry)
        end

        YouTubeG::Response::VideoSearch.new(
          :feed_id => feed_id,
          :updated_at => updated_at,
          :total_result_count => total_result_count,
          :offset => offset,
          :max_result_count => max_result_count,
          :videos => videos)
      end
    end
    
  end 
end