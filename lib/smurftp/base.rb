module Smurftp
  class Base
  
    def initialize(base_dir, config_file)
      @base_dir = base_dir
      @config_file = config_file
      @configuration = Configuration.new
      @file_queue = {}
      @last_upload = nil
      @templates_dir = File.dirname(__FILE__) + '/templates'
    end

    
    def run()
      read_configuration_file
      validate_configuration
      set_base_dir
      refresh_file_queue(find_files)
      get_user_input
    end
    
    
    def read_configuration_file
      YAML::load_file(@config_file).each do |name, value|
        if name == 'exclusions'
          value.each do |exclude|
            #TODO find a way to convert strings regexps in yaml to real regex objects
            @configuration['exclusions'] << exclude
          end
        else
          @configuration[name] = value
        end
      end
    end
    
    
    def set_base_dir
      unless @base_dir
        @base_dir = @configuration['document_root']
      end
    end

    
    def validate_configuration
      @configuration.required.each do |setting|
        unless @configuration[setting]
          raise StandardError, "Error: \"#{setting}\" is missing from configuration file."
        end
      end
    end
    
    
    def generate_config(dir)
      copy_file("#{@templates_dir}/smurftp_config.yaml", "#{dir}/smurftp_config.yaml")
      puts "No configuration file found. Creating new file."
      puts "New configuration file created in #{dir}."
      puts "Enter server and login info in this file and restart smurftp."
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


    # A all
    # L, ls, r refresh list
    # 1 any number or range uploads those files
    # ^1 ommits that file
    # 1,2,4-7,^5 or !5
    # More, list more files
    # E, q quit

    def get_user_input
      puts 'Enter files for upload:'
      command = gets.downcase
      case command
        when /^(a|all)/: upload_all
        when /^(e|exit|q|quit)/: quit
        when /^(m|more)/: list_more_files
        when /^\d+(\.+|-)\d+/: parse_command_as_range(command)
        when /^\d+/: parse_command_as_single(command)
        when /^\d+,/: parse_command_as_list(command)
        else 
      end
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
    
    def quit
      puts 'Peace Out, Dawg!'
      messages = [
        'Hasta La Vista, Baby!',
        'Peace Out, Dawg!']
    end

  end
end
