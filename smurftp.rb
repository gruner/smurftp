#!/usr/bin/env ruby -wKU

require 'net/ftp'
require 'rubygems'
require 'rio'

class Smurftp
  
  def initialize(config_file)
    @config = config_file
    self.exception_list = []
    self.find_directories = ['.']
    self.last_upload = nil
    this.run
  end
  
  
  def run
    self.last_upload = Time.now
  end
  
  
  def refresh
    
  end
  
  
  def parse_input
  end
  
  
  def method_name
    
  end
  
  ##
  # Find the files to process, ignoring temporary files, source
  # configuration management files, etc., and return a Hash mapping
  # filename to modification time.

  def find_files
    result = {}
    targets = self.find_directories

    targets.each do |target|
      order = []
      Find.find(target) do |f|
        Find.prune if f =~ self.exception_list

        next if f =~ /(swp|~|rej|orig|bak)$/ # temporary/patch files
        next if f =~ /\/\.?#/            # Emacs autosave/cvs merge files

        filename = f.sub(/^\.\//, '')
        
        if File.stat(filename).mtime > self.last_upload
          result[filename] = File.stat(filename).mtime rescue next
        end
        
      end
    end

    return result
  end
  
  
  def upload(file_que)
    ftp = Net::FTP.new(@config[:server])
    ftp.login(@config[:user], @config[:pass])
    ftp.getbinaryfile('nif.rb-0.91.gz', 'nif.gz', 1024)
    file_que.each do |file, path|
      ftp.put(file, "#{@config[:server_root]}/path")
    end
    ftp.close
    self.last_upload = Time.now
  end
  
  
  
end