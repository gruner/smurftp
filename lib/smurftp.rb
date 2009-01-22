require 'yaml'
require 'find'
require 'fileutils'
require 'net/ftp'
require 'readline'
# require 'rubygems'
# other dependencies

# a bit of monkey patching

class String
  def to_regex!
    return /#{self}/
  end
end


class Hash
  # Destructively convert all keys to symbols.
  def symbolize_keys!
    self.each do |key, value|
      unless key.is_a?(Symbol)
        self[key.to_sym] = self[key]
        delete(key)
      end
      # recursively call this method on nested hashes
      value.symbolize_keys! if value.class == Hash
    end
    self
  end
end

%w(version configuration shell).each do |file|
  require File.join(File.dirname(__FILE__), 'smurftp', file) 
end