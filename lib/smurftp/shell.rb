# Smurftp::Shell is used to create an interactive shell. It is invoked by the smurftp binary.
module Smurftp
  class Shell

    attr_reader :upload_queue, :file_list

    def initialize(config_file, site=nil)
      #Readline.basic_word_break_characters = ""
      #Readline.completion_append_character = nil
      @configuration = Smurftp::Configuration.new(config_file, site)
      @base_dir = @configuration[:document_root]
      @file_list = []
      @upload_queue = []
      @last_upload = nil
    end


    # Run a single command.
    def parse_command(cmd)
      case cmd.downcase
        when /^(a|all)$/
          return lambda { upload_all }
        when /\d+,/ # digit comma
          files = parse_list(cmd)
          command = lambda { upload }
          return command, files
        when /\d+(\.+|-)\d+/ 
          files = parse_range(cmd)
          command = lambda { upload }
          return command, files
        when /^\d+/
          file = [cmd]
          command = lambda { upload }
          return command, file
        # when /^(m|more)/: list_more_queued_files
        when /^(r|refresh|l|ls|list)$/
          command = lambda do
            find_files
            refresh_file_display
          end
          return command
        else
          return 'error'
        # TODO needs error message as fallback
      end
    end
    
    
    # Run the interactive shell using readline.
    def run
      find_files
      refresh_file_display
      loop do
        cmd = Readline.readline('smurftp> ')
        finish if cmd.nil? or cmd =~ /^(e|exit|q|quit)$/
        next if cmd == ""
        Readline::HISTORY.push(cmd)
        command, files = parse_command(cmd)
        if files
          add_files_to_queue(files)
        end
        command.call
      end
    end
    
    
    ##
    # Adds single file to upload queue, ensuring
    # no duplicate additions
    
    def add_file_to_queue(str)
      str.gsub!(/[^\d]/, '') #strip non-digit characters
      file = str.to_i-1
      @upload_queue << file unless @upload_queue.include?(file)
    end
    
    
    def add_files_to_queue(files)
      files.each {|f| add_file_to_queue(f)}
    end
    
    
    ##
    # Extract a list of comma separated values from a string.
    # Look for ranges and expand them, look for exceptions
    # and remove them from the returned list.
    
    def parse_list(str)
      file_list = []
      exceptions = []
      str.split(',').each do |s|
        if s =~ /-/
          file_list += parse_range(s)
        elsif s =~ /(\^|!)\d/
          s.gsub!(/[^\d]/, '') #strip non-digit characters
          exceptions << s
        else
          file_list << s
        end
      end
      return file_list - exceptions
    end
    
    
    ##
    # Extract a range of numbers from a string.
    # Expand the range into an array that represents files
    # in the displayed list, and returns said array.
    
    def parse_range(str)
      delimiters = str.split(/\.+|-+/)
      r_start, r_end = delimiters[0], delimiters[1]
      # TODO assumes even number pairs for creating a range
      range = r_start.to_i..r_end.to_i
      file_list = []
      range.each do |n|
        file_list << n.to_s
      end
      return file_list
    end
    
    
    def list_more_queued_files
      # TODO
      # not sure how this will work yet
    end


    ##
    # Format the output of the file list display by looping over
    # @file_list and numbering each file up to the predefined queue limit.
    
    def refresh_file_display
      if @last_upload
        puts 'Files changed since last upload:'
      else
        puts 'Recently modified files:'
      end
      
      file_count = 1
      @file_list.each do |f|
        unless file_count > @configuration[:queue_limit]
          spacer = ' ' unless file_count > 9 #add space to even the file numbering column
          puts "#{spacer}[#{file_count}] #{f[:base_name]}"
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
    # configuration management files, etc., and add them to @file_list mapping
    # filename to modification time.

    def find_files
      @file_list.clear
      Find.find(@base_dir) do |f|
        
        @configuration[:exclusions].each do |e|
          Find.prune if f =~ e.to_regex!
          # if e.class == Regexp
          #   Find.prune if f =~ e.to_regex!
          # end
        end

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
      #TODO add timeout error handling
      created_dirs = []
      Net::FTP.open(@configuration[:server]) do |ftp|
        ftp.login(@configuration[:login], @configuration[:password])
        @upload_queue.each do |file_id|
          file = @file_list[file_id]
          
          dirs = parse_file_for_sub_dirs(file[:base_name])
          dirs.each do |dir|
            unless created_dirs.include? dir
              begin
                ftp.mkdir "#{@configuration[:server_root]}/#{dir}"
                puts "created #{dir}..."
              rescue Net::FTPPermError; end #ignore errors for existing dirs
              created_dirs << dir
            end
          end
          
          puts "uploading #{file[:base_name]}..."
          ftp.put("#{file[:name]}", "#{@configuration[:server_root]}/#{file[:base_name]}")
          # @file_list.delete_at file_id
          # @upload_queue.delete file_id
        end
      end
      @upload_queue.clear
      puts "done"
      @last_upload = Time.now
    end


    def upload_all
      @file_list.length.times { |f| @upload_queue << f+1 }
      upload
    end
    
    
    def parse_file_for_sub_dirs(file)
      dirs = file.split(/\//)
      return [] if dirs.length <= 1
      dirs_expanded = []
      
      while dirs.length > 1
        dirs.pop
        dirs_expanded << dirs.join('/')
      end

      return dirs_expanded.reverse
    end


    ##
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