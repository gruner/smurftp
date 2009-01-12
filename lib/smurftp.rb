require 'rubygems'
# other dependencies

require File.dirname(__FILE__) + '/smurftp/helpers'

%w(version configuration error base server).each do |file|
  require File.join(File.dirname(__FILE__), 'smurftp', file) 
end

