require 'fileutils'

module Smurftp
  class Base
    # Directories generated for a new site setup
    @@base_dirs = %w{
      site/
      site/stylesheets
      site/images
      site/javascripts
      src/
      src/pages/
      src/layouts
      src/stylesheets
      src/partials
      src/helpers
    }
  
    # Templates for setup and their location
    @@templates = {
      'application.haml' => 'layouts',
      'application.sass' => 'stylesheets',
      'index.haml' => 'pages'
    }
    
    attr_accessor :configuration
    attr_reader :current_page, :src_dir, :site_dir

    def current_file
      @current_file_stack[0]
    end
    
    def initialize(base_dir, configuration = Configuration.new)
      @configuration = configuration
      @current_page = nil
      @current_file_stack = []
      @base_dir = base_dir
      @templates_dir = File.dirname(__FILE__) + '/templates'
      @layout = "application"
      @scope = Object.new
      @scope.instance_variable_set("@staticmatic", self)
      load_helpers
    end
    
    def base_dir
      @base_dir
    end
  
    def run(command)
      if %w(build setup preview).include?(command)
        send(command)
      else
        puts "#{command} is not a valid StaticMatic command"
      end
    end

    
    def setup
      Dir.mkdir(@base_dir) unless File.exists?(@base_dir)
    
      @@base_dirs.each do |directory|
        directory = "#{@base_dir}/#{directory}"
        if !File.exists?(directory)
          Dir.mkdir(directory)
          puts "created #{directory}"
        end
      end
  
      @@templates.each do |template, destination|
        copy_file("#{@templates_dir}/#{template}", "#{@src_dir}/#{destination}")
      end
  
      puts "Done"
    end
    
    def preview
      puts "StaticMatic Preview Server Starting..."
      StaticMatic::Server.start(self)
    end
  
    def copy_file(from, to)
      FileUtils.cp(from, to)
    end
  
    def save_page(filename, content)
      generate_site_file(filename, 'html', content)
    end
  
    def save_stylesheet(filename, content)
      generate_site_file(File.join('stylesheets', filename), 'css', content)
    end
  
    def generate_site_file(filename, extension, content)
      path = File.join(@site_dir,"#{filename}.#{extension}")
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w+') do |f|
        f << content
      end
      
      puts "created #{path}"
    end
    
    def source_for_layout
      if layout_exists?(@layout)
        File.read(full_layout_path(@layout))
      else
        raise StaticMatic::Error.new("", full_layout_path(@layout), "Layout not found")
      end
    end
    
    # Generate html from source file:
    # generate_html("index.haml")
    def generate_html(source_file, source_dir = '')
      full_file_path = File.join(@src_dir, 'pages', source_dir, "#{source_file}.haml")

      begin
        # clear all scope variables except @staticmatic
        @scope.instance_variables.each do |var|
          @scope.instance_variable_set(var, nil) unless var == '@staticmatic' 
        end
        html = generate_html_from_template_source(File.read(full_file_path))
      
        @layout = detirmine_layout(source_dir)
      rescue StaticMatic::Error => staticmatic_error
        # Catch any errors from the actual template - otherwise the error will be assumed to be from the
        # layout
        raise staticmatic_error
      rescue Haml::Error => haml_error
        raise StaticMatic::Error.new(haml_error.line_offset, "#{source_dir}/#{source_file}", haml_error.message)
      end
      
      # 
      # # TODO: DRY this up
      # if @scope.instance_variable_get("@layout")
      #   @layout = @scope.instance_variable_get("@layout")
      # end
      # 
      html
    end
    
    def generate_html_with_layout(source, source_dir = '')
      @current_page = File.join(source_dir, "#{source}.html")
      @current_file_stack.unshift(File.join(source_dir, "#{source}.haml"))

      template_content = generate_html(source, source_dir)
      @layout = detirmine_layout(source_dir)
      
      begin
        generate_html_from_template_source(source_for_layout) { template_content }
      rescue StaticMatic::Error => staticmatic_error
        # Catch any errors from the actual template - otherwise the error will be assumed to be from the
        # layout
        raise staticmatic_error
      rescue Haml::Error => haml_error
        raise StaticMatic::Error.new("", "Layout: #{source_dir}/#{@layout}", haml_error.message)
      ensure
        @current_page = nil
        @current_file_stack.shift
      end
    end
    
    def generate_partial(name, options = {})
      partial_dir, partial_name = File.dirname(self.current_file), name  # default relative to current file
      partial_dir, partial_name = File.split(name) if name.index('/') # contains a path so it's absolute from src/pages dir
      partial_name = "_#{partial_name}.haml"

      partial_path = File.join(@src_dir, 'pages', partial_dir, partial_name)
      unless File.exists?(partial_path)
        # couldn't find it in the pages subdirectory tree so try old way (ignoring the path)
        partial_dir = 'partials'; partial_name = "#{File.basename(name)}.haml"
        partial_path = File.join(@src_dir, partial_dir, partial_name)
      end
      
      if File.exists?(partial_path)
        partial_rel_path = "/#{partial_dir}/#{partial_name}".gsub(/\/+/, '/')
        @current_file_stack.unshift(partial_rel_path)
        begin
          generate_html_from_template_source(File.read(partial_path), options)
        rescue Haml::Error => haml_error
          raise StaticMatic::Error.new(haml_error.haml_line, "Partial: #{partial_rel_path[0,partial_rel_path.length-5]}", haml_error.message)
        ensure
          @current_file_stack.shift
        end
      else
        raise StaticMatic::Error.new("", name, "Partial not found")
      end
    end

    def generate_css(source, source_dir = '')
      full_file_path = File.join(@src_dir, 'stylesheets', source_dir, "#{source}.sass")
      begin
        sass_options = { :load_paths => [ File.join(@src_dir, 'stylesheets') ] }.merge(self.configuration.sass_options)
        stylesheet = Sass::Engine.new(File.read(full_file_path), sass_options)
        stylesheet.to_css
      rescue Sass::SyntaxError => sass_error
        raise StaticMatic::Error.new(sass_error.sass_line, full_file_path, sass_error.message)
      end
    end
    
    # Generates html from the passed source string
    #
    # generate_html_from_template_source("%h1 Welcome to My Site") -> "<h1>Welcome to My Site</h1>"
    #
    # Pass a block containing a string to yield within in the passed source:
    #
    # generate_html_from_template_source("content:\n= yield") { "blah" } -> "content: blah"
    #
    def generate_html_from_template_source(source, options = {})
      html = Haml::Engine.new(source, options)

      html.render(@scope) { yield }
    end
    
    def detirmine_layout(dir = '')
      layout_name = "application"
      
      if @scope.instance_variable_get("@layout")
        layout_name = @scope.instance_variable_get("@layout")
      elsif dir
        dirs = dir.split("/")
        dir_layout_name = dirs[1]
        
        if layout_exists?(dir_layout_name)
          layout_name = dir_layout_name
        end
      end

      layout_name
    end
  
    # TODO: DRY this _exists? section up
    def template_exists?(name, dir = '')
      File.exists?(File.join(@src_dir, 'pages', dir, "#{name}.haml")) || File.exists?(File.join(@src_dir, 'stylesheets', "#{name}.sass"))
    end
    
    def layout_exists?(name)
      File.exists? full_layout_path(name)
    end
    
    def template_directory?(path)
      File.directory?(File.join(@src_dir, 'pages', path))
    end
    
    def full_layout_path(name)
      "#{@src_dir}/layouts/#{name}.haml"
    end
    
    # Build HTML from the source files
    def build_html
      Dir["#{@src_dir}/pages/**/*.haml"].each do |path|
        next if File.basename(path) =~ /^\_/  # skip partials
        file_dir, template = source_template_from_path(path.sub(/^#{@src_dir}\/pages/, ''))
        save_page(File.join(file_dir, template), generate_html_with_layout(template, file_dir))
      end
    end
  
    # Build CSS from the source files
    def build_css
      Dir["#{@src_dir}/stylesheets/**/*.sass"].each do |path|
        file_dir, template = source_template_from_path(path.sub(/^#{@src_dir}\/stylesheets/, ''))
        save_stylesheet(File.join(file_dir, template), generate_css(template, file_dir))
      end
    end
    
    # Returns a raw template name from a source file path:
    # source_template_from_path("/path/to/site/src/stylesheets/application.sass")  ->  "application"
    def source_template_from_path(path)
      file_dir, file_name = File.split(path)
      file_name.chomp!(File.extname(file_name))
      [ file_dir, file_name ]
    end
    
    # Loads any helpers present in the helpers dir and mixes them into the template helpers
    def load_helpers

      Dir["#{@src_dir}/helpers/**/*_helper.rb"].each do |helper|
        load_helper(helper)
      end
    end

    def load_helper(helper)
      load helper
      module_name = File.basename(helper, '.rb').gsub(/(^|\_)./) { |c| c.upcase }.gsub(/\_/, '')
      Haml::Helpers.class_eval("include #{module_name}")
    end
    
    class << self
      def base_dirs
        @@base_dirs
      end
    end
  end
end
