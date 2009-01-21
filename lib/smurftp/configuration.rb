module Smurftp
  class Configuration < Hash

    def self.generate_config_file(dir)
      # TODO ask before creating new file
      # TODO fill out the config file by promption user for the info
      templates_dir = File.dirname(__FILE__) + '/templates'
      FileUtils.cp("#{templates_dir}/smurftp_config.yaml", "#{dir}/smurftp_config.yaml")
      puts "No configuration file found. Creating new file."
      puts "New configuration file created in #{dir}."
      puts "Enter server and login info in this file and restart smurftp."
    end


    def initialize(file)
      self[:exclusions] = [file] #exclude config file from upload if it's in the @base_dir
      self[:queue_limit] = 15
      load_config_file(file)
      validate
    end


    def load_config_file(file)
      YAML::load_file(file).each do |name, value|
        if name == 'exclusions'
          value.each do |exclude|
            # if exclude =~ /^\/.*\/$/
            #   exclude.sub!(/^\/.*\/$/,$1)
            #   exclude = exclude.to_regex
            # end
            self[:exclusions] << exclude
          end
        else
          self[name.to_sym] = value
        end
      end
    end


    def validate
      %w[server server_root document_root login password].each do |setting|
        unless self[setting.to_sym]
          raise StandardError, "Error: \"#{setting}\" is missing from configuration file."
        end
      end
      unless File.directory?(self[:document_root])
        raise StandardError, "Error: \"#{self[:document_root]}\" specified in configuration file is not a valid directory."
      end
    end

  end
end