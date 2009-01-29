require 'test/unit'
require File.dirname(__FILE__) + '/../lib/smurftp'

class SmurftpShellTest < Test::Unit::TestCase
  def setup
    @config = File.dirname(__FILE__) + '/../lib/smurftp/templates/smurftp_config.yaml'
    @smurftp = Smurftp::Shell.new(@config)
  end


  def test_should_parse_list
    lists = [
      ['1,2,3',['1','2','3']],
      ['1-4,^3',['1','2','4']],
      ['1,2,3-6,^4',['1','2','3','5','6']],
      ['1,2,3-6,!4',['1','2','3','5','6']],
      ['^4,1-6',['1','2','3','5','6']]
    ].each do |input, expected|
      assert_equal expected, @smurftp.parse_list(input)
    end
  end


  def test_should_parse_range
    assert_equal ['1','2','3','4'], @smurftp.parse_range('1-4')
  end
  
  
  def test_should_parse_file_for_sub_dirs
    file_paths = [
      ['one/two/three/file.txt',['one','one/two','one/two/three']],
      ['file.txt',[]]
    ].each do |file,expanded|
      assert_equal expanded, @smurftp.parse_file_for_sub_dirs(file)
    end
  end


  def test_should_add_files_to_queue
    @smurftp.add_files_to_queue(['1','2','3','4'])
    assert_equal [0,1,2,3], @smurftp.upload_queue
  end


  def test_upload_queue_should_be_unique
    @smurftp.add_files_to_queue(['1','2','3','4','2','3','1','1','1'])
    assert_equal [0,1,2,3], @smurftp.upload_queue
  end
  
  
  def test_parse_command_should_parse_input
    input = @smurftp.parse_command('all')
    assert_equal Proc, input.class

    input = @smurftp.parse_command('a')
    assert_equal Proc, input.class
    
    input = @smurftp.parse_command('ardvark')
    assert_equal 'error', input

    input = @smurftp.parse_command('allin')
    assert_equal 'error', input

    cmd, files = @smurftp.parse_command('1')
    assert_equal ['1'], files

    cmd = @smurftp.parse_command(' 1 ')
    assert_equal 'error', cmd
    
    cmd, files = @smurftp.parse_command('1,2,3,4')
    assert_equal ['1','2','3','4'], files
    
    cmd, files = @smurftp.parse_command('1-4')
    assert_equal ['1','2','3','4'], files
    
    cmd, files = @smurftp.parse_command('1-4,^3')
    assert_equal ['1','2','4'], files
    
    cmd, files = @smurftp.parse_command('^3,1-4')
    assert_equal ['1','2','4'], files
  end


  def test_hash_symbolize_keys
    assert_equal({:yada => 'yada'}, {'yada' => 'yada'}.symbolize_keys!)
    expected = {:yada => {:yada => {:yada => 'yada'}}}
    sample = {'yada' => {'yada' => {'yada' => 'yada'}}}
    assert_equal expected, sample.symbolize_keys!
  end

end