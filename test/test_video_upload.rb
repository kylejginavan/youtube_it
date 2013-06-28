require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestVideoUpload < Test::Unit::TestCase

  def setup
    @vu = YouTubeIt::Upload::VideoUpload.new :usename => 'tubeit20101'
  end

  def test_should_extract_error_description_from_xml
    body = "<errors xmlns='http://schemas.google.com/g/2005'>
              <error>
                <domain>GData</domain>
                <code>ServiceUnavailableException</code>
                <internalReason>Service Unavailable</internalReason>
              </error>
            </errors>"

    assert_equal "Service Unavailable: ServiceUnavailableException\n", @vu.send(:parse_upload_error_from, body)
  end

  def test_should_extract_error_description_from_html
    body = '<HTML>
              <HEAD>
                <TITLE>Token invalid - Invalid token: Stateless token expired</TITLE>
              </HEAD>
              <BODY BGCOLOR="#FFFFFF" TEXT="#000000">
                <H1>Token invalid - Invalid token: Stateless token expired</H1>
                <H2>Error 401</H2>
              </BODY>
            </HTML>'

    assert_equal "Token invalid - Invalid token: Stateless token expired", @vu.send(:parse_upload_error_from, body)

    body = '<HTML>
              <HEAD>
                <TITLE>NoLinkedYouTubeAccount</TITLE>
              </HEAD>
              <BODY BGCOLOR="#FFFFFF" TEXT="#000000">
                <H1>NoLinkedYouTubeAccount</H1>
                <H2>Error 401</H2>
              </BODY>
            </HTML>'

    assert_equal "NoLinkedYouTubeAccount", @vu.send(:parse_upload_error_from, body)
  end

  def test_partial_video_xml_title
    xml = @vu.send(:partial_video_xml, { :title => 'new_title' })
    assert_equal '<?xml version="1.0" encoding="UTF-8"?><entry xmlns="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/" xmlns:gd="http://schemas.google.com/g/2005" xmlns:yt="http://gdata.youtube.com/schemas/2007" xmlns:gml="http://www.opengis.net/gml" xmlns:georss="http://www.georss.org/georss"><media:group><media:title type="plain">new_title</media:title></media:group></entry>', xml
  end

  def test_partial_video_xml_list_access_control
    xml = @vu.send(:partial_video_xml, { :list => 'allowed' })
    assert_equal '<?xml version="1.0" encoding="UTF-8"?><entry xmlns="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/" xmlns:gd="http://schemas.google.com/g/2005" xmlns:yt="http://gdata.youtube.com/schemas/2007" xmlns:gml="http://www.opengis.net/gml" xmlns:georss="http://www.georss.org/georss" gd:fields="yt:accessControl[@action=\'list\']"><media:group></media:group><yt:accessControl action="list" permission="allowed"/></entry>', xml
  end

  def test_uri?
    res = @vu.uri?("http://media.railscasts.com/assets/episodes/videos/412-fast-rails-commands.mp4")

    assert_equal true, res
  end

end
