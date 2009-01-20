require 'yaml'
require 'find'
require 'fileutils'
require 'net/ftp'
require 'readline'
# require 'rubygems'
# other dependencies

# a bit of monkey patching
class String
  def to_regex
    return /#{self}/
  end
end

%w(version configuration shell).each do |file|
  require File.join(File.dirname(__FILE__), 'smurftp', file) 
end