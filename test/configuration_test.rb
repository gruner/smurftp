require 'test/unit'
require File.dirname(__FILE__) + '/../lib/smurftp'

class SmurftpConfigurationTest < Test::Unit::TestCase
  def setup
    @config_file = File.dirname(__FILE__) + '/../lib/smurftp/templates/smurftp_config.yaml'
    @multisite_config_file = File.dirname(__FILE__) + '/../lib/smurftp/templates/smurftp_multisite_config.yaml'
  end

  
  def test_hash_symbolize_keys
    assert_equal({:yada => 'yada'}, {'yada' => 'yada'}.symbolize_keys!)
    expected = {:yada => {:yada => {:yada => 'yada'}}}
    sample = {'yada' => {'yada' => {'yada' => 'yada'}}}
    assert_equal expected, sample.symbolize_keys!
  end

  def test_configuration
    config = Smurftp::Configuration.new(@config_file)
  end
  
  def test_multisite_configuration
    config = Smurftp::Configuration.new(@multisite_config_file, 'site1')
    puts config.inspect
  end

end