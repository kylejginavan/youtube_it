# Stream wrapper that read's IOs in succession. Can be fed to Net::HTTP. We use it to send a mixture of StringIOs
# and File handles to Net::HTTP which will be used when sending the request, not when composing it. Will skip over
# depleted IOs. Can be also used to roll across files like so:
#
#   tape = TapeIO.new(File.open(__FILE__), File.open('/etc/passwd'))
require 'delegate'
class YouTubeG
  class ChainIO
    attr_accessor :substreams
    attr_accessor :release_after_use
  
    def initialize(*any_ios)
      @release_after_use = true
      @pending = any_ios.flatten.map{|e| e.respond_to?(:read)  ? e : StringIO.new(e.to_s) }
    end
  
    def read(buffer_size = 1024)
      # Read off the first element in the stack
      current_io = @pending.shift
      return false if !current_io
    
      buf = current_io.read(buffer_size)
      if !buf && @pending.empty? # End of streams
        release_handle(current_io)
        false
      elsif !buf # This IO is depleted, but next one is available
        release_handle(current_io)
        read(buffer_size)
      elsif buf.length < buffer_size # This IO is depleted, but there might be more
        release_handle(current_io)
        buf + (read(buffer_size - buf.length) || '') # and recurse
      else # just return the buffer
        @pending.unshift(current_io) # put the current back
        buf
      end
    end
    
    def expected_length
      @pending.inject(0) do | len, io |
        if io.respond_to?(:length)
          len + (io.length - io.pos)
        elsif io.is_a?(File)
          len + File.size(io.path) - io.pos
        else
          raise "Cannot predict length of #{io.inspect}"
        end
      end
    end
    
    private
      def release_handle(io)
        return unless @release_after_use
        io.close if io.respond_to?(:close)
      end
  end
  
  class GreedyChainIO < DelegateClass(ChainIO)
    CHUNK = 512 * 1024 # 500 kb
    
    def initialize(*with_ios)
      __setobj__(ChainIO.new(with_ios))
    end
    
    def read(any_buffer_size)
      __getobj__.read(CHUNK)
    end
  end
end