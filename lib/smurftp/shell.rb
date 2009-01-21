# Smurftp::Shell is used to create an interactive shell. It is invoked by the smurftp binary.
module Smurftp
  class Shell
    
    attr_reader :upload_queue, :file_list

    def initialize(config_file)
      #Readline.basic_word_break_characters = ""
      #Readline.completion_append_character = nil
      @configuration = Smurftp::Configuration.new(config_file)
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
          add_files_to_queue(parse_range(cmd))
          upload
        when /^\d+,/
          add_files_to_queue(parse_list(cmd))
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
        finish if cmd.nil? or cmd =~ /^(e|q)/
        next if cmd == ""
        Readline::HISTORY.push(cmd)
        execute(cmd)
      end
    end
    
    
    def add_file_to_queue(str)
      str.gsub!(/[^\d]/, '') #strip non-digit characters
      @upload_queue << str.to_i-1
    end
    
    
    def add_files_to_queue(files)
      files.each {|f| add_file_to_queue(f)}
    end
    
    
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
        
        @configuration[:exclusions].each do |e|
          Find.prune if f =~ e.to_regex
          # if e.class == Regexp
          #   Find.prune if f =~ e.to_regex
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
        @upload_queue.uniq!
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
      return [] if dirs.length <= 1
      dirs_expanded = []
      
      while dirs.length > 1
        dirs.pop
        dirs_expanded << dirs.join('/')
      end

      return dirs_expanded.reverse
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