# Smurftp::Shell is used to create an interactive shell. It is invoked by the smurftp binary.
module Smurftp
  class Shell
    
    def initialize(base_dir, config_file)
      #Readline.basic_word_break_characters = ""
      #Readline.completion_append_character = nil
      @configuration = Smurftp::Configuration.new(config_file)
      @base_dir = base_dir != '' ? base_dir : @configuration[:document_root]
      @file_list = []
      @upload_queue = []
      @last_upload = nil
    end


    # ^1 ommits that file
    # 1,2,4-7,^5 or !5

    # Run a single command.
    def execute(cmd)
      case cmd.downcase
        when /^(a|all)/
          upload_all
        when /^\d+(\.+|-)\d+/
          parse_file_range(cmd)
          upload
        when /^\d+/
          parse_file_id(cmd)
          upload
        when /^\d+,/
          parse_file_list(cmd)
          upload
        # when /^(m|more)/: list_more_queued_files
        when /^(r|refresh|l|ls|list)/: refresh_file_queue(find_files)
        else
      end
    end
    
    
    def parse_file_list(cmd, type)
      files = case type
        when 'single': 
        when 'range': 
        when 'list'
          cmd.split(',').each do |f|
            f.strip!
            if f =~ /-/
              f = parse_file_list(f, 'range')
            else
              f = f.to_i
            end
          end
        when 'all': @file_queue
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
    
    
    def parse_file_id(str)
      str.gsub!(/[^\d]/, '') #strip non-digit characters
      @upload_queue << str.to_i
    end
    
    
    def parse_file_list(str)
      str.split(',').each do |f|
        f.strip!
        if f =~ /-/
          parse_file_range(f)
        elsif f =~ /(\^|!)\d/
          f.gsub!(/[^\d]/, '') #strip non-digit characters
          @upload_queue.delete(f.to_i)
        else
          parse_file_id f
        end
      end
    end
    
    
    def parse_file_range(str)
      
    end
    
    
    def list_more_queued_files
      # TODO
      # not sure how this will work yet
    end


    def refresh_file_queue(files)
      if @last_upload
        puts 'Files changed since last upload:'
      else
        puts 'Recently modified files:'
      end
      
      file_count = 1
      files.each do |f|
        unless file_count > @configuration[:queue_limit]
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

    def find_files()
      result = {}

      Find.find(@base_dir) do |f|
        Find.prune if f =~ @congiguration['exclusions']

        next if f =~ /(swp|~|rej|orig|bak)$/ # temporary/patch files
        next if f =~ /\/\.?#/            # Emacs autosave/cvs merge files
        
        #TODO loop through exclusions that are regex objects

        filename = f.sub(/^\.\//, '')
        mtime = File.stat(filename).mtime
        
        if @last_upload
          if mtime > @last_upload
            result[filename] = mtime rescue next
          end
        else #get all files, because we haven't uploaded yet
          result[filename] = mtime rescue next
        end
      end

      return result
    end


    def upload
      @upload_queue.unique!
      ftp = Net::FTP.new(@configuration['server'])
      ftp.login(@configuration[:user], @configuration['password'])
      @upload_queue.each do |f|
        ftp.put("#{@configuration['document_root']}/#{f}", "#{@configuration['server_root']}/#{f}")
        @upload_que.delete f
      end
      ftp.close
      @last_upload = Time.now
    end
    
    
    def upload_all
      @upload_queue = @file_list
      upload
    end


    # Close the shell and exit the program with a cheesy message.
    def finish
      puts 'Peace Out, Dawg!'
      messages = [
        'Hasta La Vista, Baby!',
        'Peace Out, Dawg!'
      ]
      random_msg = messages[rand(messages.length+1)]
      puts random_msg
      exit
    end
    
  end
end