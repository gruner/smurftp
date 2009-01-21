require 'test/unit'
require File.dirname(__FILE__) + '/../lib/smurftp'

class SmurftpShellTest < Test::Unit::TestCase
  def setup
    @config = File.dirname(__FILE__) + '/sandbox/test_config.yaml'
    @smurftp = Smurftp::Shell.new(@config)
  end
  
  def test_should_parse_file_for_sub_dirs
  end
  
  def test_should_add_file_to_queue
  end

  def test_should_add_list_to_queue
    @smurftp.add_list_to_queue('1,2,3')
    assert_match [0,1,2], @smurftp.upload_queue
  end
  
  def test_should_exclude_item_from_queue
    @smurftp.add_list_to_queue('1-4,^3')
    assert_match [0,1,3], @smurftp.upload_queue
  end
  
  def test_should_add_mixed_list_to_queue
    @smurftp.add_list_to_queue('1,2,3-6,^4')
    assert_match [0,1,2,4,5], @smurftp.upload_queue
  end
  
  def test_should_add_range_to_que
  end
  
end