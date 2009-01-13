require 'readline'

# Smurftp::Shell is used to create an interactive shell. It is invoked by the smurftp binary.
module Smurftp
  class Shell
    
    def initialize
      Readline.basic_word_break_characters = ""
      Readline.completion_append_character = nil
    end


    # A all
    # L, ls, r refresh list
    # 1 any number or range uploads those files
    # ^1 ommits that file
    # 1,2,4-7,^5 or !5
    # More, list more files

    # Run a single command.
    def execute(cmd)
      case cmd.downcase
      when /^(a|all)/: upload_all_queued_files
        when /^(m|more)/: list_more_queued_files
        when /^\d+(\.+|-)\d+/: parse_command_as_range(cmd)
        when /^\d+/: parse_command_as_single(cmd)
        when /^\d+,/: parse_command_as_list(cmd)
        else 
      end
    end


    # Run the interactive shell using readline.
    def run
      loop do
        cmd = Readline.readline('smurftp> ')
        finish if cmd.nil? or cmd =~ /^(e|exit|q|quit)/
        next if cmd == ""
        Readline::HISTORY.push(cmd)
        execute(cmd)
      end
    end


    # Close the shell and exit the program with a cheesy message.
    def finish
      puts 'Peace Out, Dawg!'
      messages = [
        'Hasta La Vista, Baby!',
        'Peace Out, Dawg!'
      ]
      random_msg = messages
      puts random_msg
      exit
    end


    # Nice printing of different return types, particularly Rush::SearchResults.
    def print_result(res)
      return if self.suppress_output
      if res.kind_of? String
        puts res
      elsif res.kind_of? Rush::SearchResults
        widest = res.entries.map { |k| k.full_path.length }.max
        res.entries_with_lines.each do |entry, lines|
          print entry.full_path
          print ' ' * (widest - entry.full_path.length + 2)
          print "=> "
          print res.colorize(lines.first.strip.head(30))
          print "..." if lines.first.strip.length > 30
          if lines.size > 1
            print " (plus #{lines.size - 1} more matches)"
          end
          print "\n"
        end
        puts "#{res.entries.size} matching files with #{res.lines.size} matching lines"
      elsif res.respond_to? :each
        counts = {}
        res.each do |item|
          puts item
          counts[item.class] ||= 0
          counts[item.class] += 1
        end
        if counts == {}
          puts "=> (empty set)"
        else
          count_s = counts.map do |klass, count|
            "#{count} x #{klass}"
          end.join(', ')
          puts "=> #{count_s}"
        end
      else
        puts "=> #{res.inspect}"
      end
    end

end