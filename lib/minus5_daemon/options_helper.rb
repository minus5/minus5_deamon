module Minus5
  module Service

    module OptionsHelper

      def default_options
        @cmd_options = Hashie::Mash.new(:config  => 'config')
        @options = Hashie::Mash.new(
          :app_root => app_root,
          :active   => true)
      end

      def load_config_file
        file = "#{app_root}/config/#{@cmd_options.config}.yml"
        begin
          @options.merge!(YAML.load_file(file)) 
        rescue => e
          @logger.error "failed to load config file #{file}"
        end
        @options.merge!(@cmd_options)
      end

      def parse_command_line_arguments
        @args = @opts.parse!(ARGV)
      end

      def init_command_line_arguments
        @opts = OptionParser.new do |opts|
          opts.banner = ""
          opts.on('-c','--config=CONFIG',"Specifies the name of the config file from the config dir. Default: config  (config/config.yml)") do |name|
            @cmd_options.config = name
          end
          opts.on_tail("-h", "--help", "Show this message") do
            print_usage
            exit
          end
        end
      end

      def print_usage(error = nil)
        puts "ERROR: #{error.to_s}\n" if error
        puts <<-END
  Usage: #{File.basename($0)} <options> <command>

  * where <options> may contain several of the following:
  #{@opts.to_s}
END
      end

      def app_root
        return @app_root if @app_root
        start_dir = File.expand_path(File.dirname($0))
        root_rel = ""
        #FIXME - napravi nesto da izbjegnes ove lib bin test
        root_rel = ".." if start_dir.end_with?("/lib") || 
          start_dir.end_with?("/bin") || 
          start_dir.end_with?("/test")
        @app_root = File.expand_path(File.join(File.dirname($0), root_rel))
      end

    end

  end
end
