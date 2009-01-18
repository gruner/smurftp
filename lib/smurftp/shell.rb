# Smurftp::Shell is used to create an interactive shell. It is invoked by the smurftp binary.
module Smurftp
  class Shell

    def initialize(base_dir, config_file)
      # TODO figure out if base_dir is relevant or if it's always going to be read from config
      #Readline.basic_word_break_characters = ""
      #Readline.completion_append_character = nil
      @configuration = Smurftp::Configuration.new(config_file)
      #@base_dir = base_dir != nil ? base_dir : @configuration[:document_root]
      @base_dir = @configuration[:document_root]
      @file_list = []
      @upload_queue = []
      @last_upload = nil
    end


    # Run a single command.
    def execute(cmd)
      case cmd.downcase
        when /^(a|all)/
          upload_all
        when /^\d+(\.+|-)\d+/
          add_range_to_queue(cmd)
          upload
        when /^\d+,/
          add_list_to_queue(cmd)
          upload
        when /^\d+/
          add_file_to_queue(cmd)
          upload
        # when /^(m|more)/: list_more_queued_files
        when /^(r|refresh|l|ls|list)/
          find_files
          refresh_file_display
        else
      end
    end
    
    
    # Run the interactive shell using readline.
    def run
      find_files
      refresh_file_display
      loop do
        cmd = Readline.readline('smurftp> ')
        finish if cmd.nil? or cmd =~ /^(e|exit|q|quit)/
        next if cmd == ""
        Readline::HISTORY.push(cmd)
        execute(cmd)
      end
    end
    
    
    def add_file_to_queue(str)
      str.gsub!(/[^\d]/, '') #strip non-digit characters
      @upload_queue << str.to_i-1
    end
    
    
    def add_list_to_queue(str)
      str.split(',').each do |s|
        if s =~ /-/
          parse_file_range(s)
        elsif s =~ /(\^|!)\d/
          s.gsub!(/[^\d]/, '') #strip non-digit characters
          @upload_queue.delete(s.to_i-1)
        else
          add_file_to_queue(s)
        end
      end
    end
    
    
    def add_range_to_queue(str)
      str.split(/\.+|-+/).each do |r_start, r_end|
        # TODO assumes even number pairs for creating a range
        range = r_start.to_i..r_end.to_i
        range.each {|n| @upload_que << n-1}
      end
    end
    
    
    def list_more_queued_files
      # TODO
      # not sure how this will work yet
    end


    def refresh_file_display
      if @last_upload
        puts 'Files changed since last upload:'
      else
        puts 'Recently modified files:'
      end
      
      file_count = 1
      @file_list.each do |f|
        unless file_count > @configuration[:queue_limit]
          puts "[#{file_count}] #{f[:base_name]}"
          file_count += 1
        else
          remaining_files = @file_list.length - file_count
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

    def find_files
      @file_list.clear
      Find.find(@base_dir) do |f|
        
        # this line not working
        #Find.prune if f =~ @congiguration[:exclusions]

        next if f =~ /(swp|~|rej|orig|bak|.git)$/ # temporary/patch files
        next if f =~ /\/\.?#/            # Emacs autosave/cvs merge files
        next if File.directory?(f) #skip directories
        
        #TODO loop through exclusions that are regex objects

        file_name = f.sub(/^\.\//, '')
        mtime = File.stat(file_name).mtime
        base_name = file_name.sub("#{@base_dir}/", '')
        
        if @last_upload
          if mtime > @last_upload
            @file_list << {:name => file_name,
                           :base_name => base_name,
                           :mtime => mtime} rescue next
          end
        else #get all files, because we haven't uploaded yet
          @file_list << {:name => file_name,
                           :base_name => base_name,
                           :mtime => mtime} rescue next
        end
      end
      # sort list by mtime
      @file_list.sort! { |x,y| y[:mtime] <=> x[:mtime] }
    end


    def upload
      Net::FTP.open(@configuration[:server]) do |ftp|
        ftp.login(@configuration[:login], @configuration[:password])
        @upload_queue.uniq!
        @upload_queue.each do |file_id|
          # TODO create remote folder if it doesn't exist
          file = @file_list[file_id]
          puts "uploading #{file[:base_name]}..."
          
          dirs = parse_file_for_sub_dirs(file[:base_name])
          
          
          ftp.put("#{file[:name]}", "#{@configuration[:server_root]}/#{file[:base_name]}")
          @file_list.delete_at file_id
          @upload_queue.delete file_id
        end
      end
      puts "done"
      @last_upload = Time.now
    end


    def upload_all
      @file_list.length.times { |f| @upload_queue << f+1 }
      upload
    end
    
    
    def parse_file_for_sub_dirs(file)
      dirs = file.split(/\//)
      dirs.pop #keep only the directories
      return dirs
    end
    
    
    def create_remote_sub_dir(ftp, dir)
      
    end


    # Close the shell and exit the program with a cheesy message.
    def finish
      messages = 
      [
        'Hasta La Vista, Baby!',
        'Peace Out, Dawg!',
        'Diggidy!',
        'Up, up, and away!',
        'Sally Forth Good Sir!'
      ]
      random_msg = messages[rand(messages.length)]
      puts random_msg
      exit
    end
    
  end
end