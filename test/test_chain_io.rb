require File.dirname(__FILE__) + '/helper'

class TestChainIO < Test::Unit::TestCase
  def setup
    @klass = YouTubeG::ChainIO # save typing
  end
  
  def test_should_support_read_from_one_io
    io = @klass.new "abcd"
    assert io.respond_to?(:read)
    assert_equal "ab", io.read(2)
    assert_equal "cd", io.read(2)
    assert_equal false, io.read(2)
  end
  
  def test_should_skip_over_depleted_streams
    io = @klass.new '', '', '', '', 'ab'
    assert_equal 'ab', io.read(2)
  end
  
  def test_should_read_across_nultiple_streams_with_large_offset
    io = @klass.new 'abc', '', 'def', '', 'ghij'
    assert_equal 'abcdefgh', io.read(8)
  end

  def test_should_return_false_for_empty_items
    io = @klass.new '', '', '', '', ''
    assert_equal false, io.read(8)
  end
  
  def test_should_support_overzealous_read
    io = @klass.new "ab"
    assert_equal "ab", io.read(5000)
  end
  
  def test_should_predict_expected_length
    io = @klass.new "ab", "cde"
    assert_equal 5, io.expected_length
  end

  def test_should_predict_expected_length_with_prepositioned_io
    first_buf = StringIO.new("ab")
    first_buf.read(1)
    
    io = @klass.new first_buf, "cde"
    assert_equal 4, io.expected_length
  end
  
  def test_should_predict_expected_length_with_file_handle
    test_size = File.size(__FILE__)
    first_buf = StringIO.new("ab")
    first_buf.read(1)
    
    io = @klass.new File.open(__FILE__), first_buf
    assert_equal test_size + 1, io.expected_length
  end
  
  def test_greedy
    io = YouTubeG::GreedyChainIO.new("a" * (1024 * 513))
    chunk = io.read(123)
    assert_equal 1024 * 512, chunk.length, "Should have read the first 512 KB chunk at once instead"
  end
end
