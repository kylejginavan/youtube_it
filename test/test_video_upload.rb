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
end