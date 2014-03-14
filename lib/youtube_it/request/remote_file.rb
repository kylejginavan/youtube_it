require 'open-uri'
require 'net/http'
require 'fiber'
class YouTubeIt
  module Upload


    class RemoteFile
      def initialize(url, opts)
        @pos = 0
        @url = url
        @uri = URI(@url)
        
        @content_length = opts[:content_length]

        @fiber = Fiber.new do |first|

          Net::HTTP.start(@uri.host, @uri.port) do |http|
            request = Net::HTTP::Get.new @uri.request_uri
            http.request request do |response|
              response.read_body do |chunk|
                @pos += chunk.bytesize
                Fiber.yield chunk
              end
            end
          end
        end

      end

      def ping?

      end

      def pos
        @pos
      end

      def head
        @head_result || Net::HTTP.start(@uri.host, @uri.port) do |http|
          @head_result = http.request(Net::HTTP::Head.new(@uri.request_uri))
        end
        @head_result
      end

      def filename
        File.basename(@url)
      end

      def path
        @url
      end

      def length
        @content_length ||= head.content_length
        return @content_length
      end

      def read(buf_size = 524288)
        buf = ""
        while (buf.bytesize < buf_size.to_i) && @fiber.alive?
          _chunk = @fiber.resume
          buf << _chunk if _chunk.is_a? String
        end
        buf
      end

    end
  end
end
