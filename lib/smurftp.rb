require 'yaml'
require 'find'
require 'fileutils'
require 'net/ftp'
require 'readline'
# require 'rubygems'
# other dependencies

%w(version configuration shell).each do |file|
  require File.join(File.dirname(__FILE__), 'smurftp', file) 
end