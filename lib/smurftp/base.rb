module Smurftp
  class Base
  
    def initialize(base_dir, config_file)
      @base_dir = base_dir
      @configuration = Configuration.new(config_file)
      @file_queue = {}
      @last_upload = nil
    end

    
    def run()
      set_base_dir
      refresh_file_queue(find_files)
      shell = Smurftp::Shell.new
      shell.run()
    end
    
    
    def set_base_dir
      unless @base_dir
        @base_dir = @configuration[:document_root]
      end
    end


    def refresh_file_queue(files)      
      if @last_upload
        puts 'Files changed since last upload:'
      else
        puts 'Recently modified files:'
      end
      
      file_count = 1
      files.each do |f|
        unless file_count > @queue_limit
          puts "[#{file_count}] #{f}"
          file_count += 1
        else
          remaining_files = files.length - file_count
          puts "(plus #{remaining_files} more)"
          break
        end
      end
      puts '===================='
    end


    ##
    # Find the files to process, ignoring temporary files, source
    # configuration management files, etc., and return a Hash mapping
    # filename to modification time.
  
    def find_files(last_upload)
      result = {}
  
      order = []
      Find.find(@base_dir) do |f|
        Find.prune if f =~ @congiguration['exclusions']

        next if f =~ /(swp|~|rej|orig|bak)$/ # temporary/patch files
        next if f =~ /\/\.?#/            # Emacs autosave/cvs merge files
        
        #TODO loop through exclusions that are regex objects

        filename = f.sub(/^\.\//, '')
        
        if last_upload
          
        end
        
        if File.stat(filename).mtime > last_upload
          result[filename] = File.stat(filename).mtime rescue next
        end
      end

      return result
    end


    def upload_all
      
    end


    def upload(file)
      ftp = Net::FTP.new(@configuration['server'])
      ftp.login(@configuration[:user], @configuration['password'])
      ftp.put("#{@configuration['document_root']}/#{file}", "#{@configuration['server_root']}/#{file}")
      ftp.close
      @last_upload = Time.now
    end


    def copy_file(from, to)
      FileUtils.cp(from, to)
    end

  end
end
