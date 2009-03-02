require 'delegate'
#:stopdoc:

# Stream wrapper that reads IOs in succession. Can be fed to Net::HTTP as post body stream. We use it internally to stream file content
# instead of reading whole video files into memory. Strings passed to the constructor will be wrapped in StringIOs. By default it will auto-close
# file handles when they have been read completely to prevent our uploader from leaking file handles
#
# chain = ChainIO.new(File.open(__FILE__), File.open('/etc/passwd'), "abcd")
class YouTubeG::ChainIO
  attr_accessor :autoclose

  def initialize(*any_ios)
    @autoclose = true
    @chain = any_ios.flatten.map{|e| e.respond_to?(:read)  ? e : StringIO.new(e.to_s) }
  end

  def read(buffer_size = 1024)
    # Read off the first element in the stack
    current_io = @chain.shift
    return false if !current_io
    
    buf = current_io.read(buffer_size)
    if !buf && @chain.empty? # End of streams
      release_handle(current_io) if @autoclose
      false
    elsif !buf # This IO is depleted, but next one is available
      release_handle(current_io) if @autoclose
      read(buffer_size)
    elsif buf.length < buffer_size # This IO is depleted, but we were asked for more
      release_handle(current_io) if @autoclose
      buf + (read(buffer_size - buf.length) || '') # and recurse
    else # just return the buffer
      @chain.unshift(current_io) # put the current back
      buf
    end
  end
  
  # Predict the length of all embedded IOs. Will automatically send file size.  
  def expected_length
    @chain.inject(0) do | len, io |
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
      io.close if io.respond_to?(:close)
    end
end
  
# Net::HTTP only can send chunks of 1024 bytes. This is very inefficient, so we have a spare IO that will send more when asked for 1024.
# We use delegation because the read call is recursive.
class YouTubeG::GreedyChainIO < DelegateClass(YouTubeG::ChainIO)
  BIG_CHUNK = 512 * 1024 # 500 kb
  
  def initialize(*with_ios)
    __setobj__(YouTubeG::ChainIO.new(with_ios))
  end
  
  def read(any_buffer_size)
    __getobj__.read(BIG_CHUNK)
  end
end

#:startdoc: