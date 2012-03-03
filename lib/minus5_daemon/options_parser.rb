module Minus5
  module Service

    class OptionsParser

      require 'micro-optparse'

      def initialize(&block)
        parse_command_line_options(&block)
        load_config_file
      end
      
      attr_reader :options

      def parse_command_line_options
        @command_line_options = Parser.new do |p|
          p.banner = ""
          p.version = ""
          p.option :config, "config file", :default => "config" 
          yield(p) if block_given?
        end.process!
        @command_line_options = Hashie::Mash.new(@command_line_options)
      end 

      def load_config_file
        file = find_config_file                
        @options = Hashie::Mash.new
        @options.merge!(YAML.load_file(file)) if file
        @options.merge!(@command_line_options)
      end

      def find_config_file
        start_dir = File.expand_path(File.dirname($0))
        name = @command_line_options.config
        name = "#{name}.yml" unless name.end_with?(".yml")
        [File.join(start_dir, name),
          File.join(start_dir, "../config", name),
          File.join(start_dir, "config", name)].find do |file|
          return file if File.exists?(file)
        end
      end

    end

  end
end
