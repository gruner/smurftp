# Smurftp::Shell is used to create an interactive shell. It is invoked by the smurftp binary.
module Smurftp
  class Shell
    
    def initialize(base_dir, config_file)
      Readline.basic_word_break_characters = ""
      Readline.completion_append_character = nil
      @configuration = Smurftp::Configuration.new(config_file)
      @base_dir = base_dir != '' ? base_dir : @configuration[:document_root]
      @file_queue = {}
      @last_upload = nil
    end


    # ^1 ommits that file
    # 1,2,4-7,^5 or !5

    # Run a single command.
    def execute(cmd)
      case cmd.downcase
        when /^(a|all)/: upload(parse_file_list(cmd, 'all'))
        when /^\d+(\.+|-)\d+/: upload(parse_file_list(cmd, 'range'))
        when /^\d+/: upload(parse_file_list(cmd, 'single'))
        when /^\d+,/: upload(parse_file_list(cmd, 'list'))
        when /^(m|more)/: list_more_queued_files
        when /^(r|refresh|l|ls|list)/: refresh_file_queue
        else
      end
    end
    
    
    def parse_file_list(cmd, type)
      files = case type
        when 'single': 
        when 'range': 
        when 'list':
        when 'all': 
      end
      return files
    end


    # Run the interactive shell using readline.
    def run
      refresh_file_queue(find_files)
      loop do
        cmd = Readline.readline('smurftp> ')
        finish if cmd.nil? or cmd =~ /^(e|exit|q|quit)/
        next if cmd == ""
        Readline::HISTORY.push(cmd)
        execute(cmd)
      end
    end
    
    
    def list_more_queued_files
      
    end




    # Close the shell and exit the program with a cheesy message.
    def finish
      puts 'Peace Out, Dawg!'
      messages = [
        'Hasta La Vista, Baby!',
        'Peace Out, Dawg!'
      ]
      random_msg = messages[rand(mesages.count+1)]
      puts random_msg
      exit
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


    def upload(files)
      ftp = Net::FTP.new(@configuration['server'])
      ftp.login(@configuration[:user], @configuration['password'])
      files.each do |f|
        ftp.put("#{@configuration['document_root']}/#{f}", "#{@configuration['server_root']}/#{f}")
      end
      ftp.close
      @last_upload = Time.now
    end

  end
end