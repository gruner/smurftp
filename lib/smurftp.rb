require 'yaml'
require 'find'
require 'fileutils'
require 'net/ftp'
# require 'rubygems'
# other dependencies

%w(version configuration error base).each do |file|
  require File.join(File.dirname(__FILE__), 'smurftp', file) 
end