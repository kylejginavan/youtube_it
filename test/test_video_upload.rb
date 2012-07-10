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
end