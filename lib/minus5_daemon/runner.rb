module Minus5
  module Daemon

    def self.run(klass)
      Runner.new(klass).run
    rescue => e
      print "#{e}\n#{e.backtrace}\n"
    end


    class Runner

      def initialize(klass)
        @klass = klass
        init_logger
        @config_file_set = false
        @options = Hashie::Mash.new(
          :daemonize => true,
          :config_file => 'config.yml',
          :environment => 'production',
          :app_name => start_script_name,
          :app_root => app_root)
        parse_arg_options
        load_config
        load_environment_file
      end

      attr_reader :logger

      def run
        mkdirs
        Daemons.run_proc(@options.app_name, daemon_options) do
          logger.info "starting daemon pid: #{Process.pid}"
          logger.debug "options: #{@options}"
          service = @klass.new(@options, @logger)
          service.run
        end
      end

      private

      def load_environment_file
        file = "#{@options.app_root}/config/#{@options.environment}.yml"
        if File.exists?(file)
          @options.merge!(YAML.load_file(file))
        end
      end

      def load_config
        config_file = "#{@options.app_root}/config/#{@options.config_file}"
        if File.exists?(config_file)
          @options.config = Hashie::Mash.new(YAML.load_file(config_file))
        else
          if @config_file_set
            msg = "config file #{config_file} not found"
            @logger.error msg
            raise msg
          end
        end
      end

      def init_logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
        @logger.datetime_format = "%H:%M:%S"
        @logger.formatter = proc { |severity, datetime, progname, msg|
          "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} #{severity}: #{msg}\n"
        }
      end

      def parse_arg_options
        opts = OptionParser.new do |opts|
          opts.banner = "Usage: #{start_script_name} [options]"
          opts.separator ''
          opts.on('-n','--no-daemonize',"Don't run as a daemon") do
            @options.daemonize = false
          end
          opts.on('-e','--environment=name',"Specifies the environment to run this server under. Default: production") do |name|
            @options.environment = name
          end
          opts.on('-c','--config=file',"Use specified config file. This is yaml config file name from app_root/config dir.") do |file|
            file = "#{file}.yml" unless file.include?(".")
            @options.config_file = file
            @config_file_set = true
          end
          opts.on('-a','--app-name=file',"Use specified application name for daemon process.") do |name|
            @options.app_name = name
          end
        end
        @args = opts.parse!(ARGV)
      end

      def daemon_options
        {
          :backtrace  => true,
          :dir_mode   => :normal,
          :log_output => true,
          :dir        => pid_dir,
          :log_dir    => log_dir,
          :ARGV       => @args,
          :ontop      => !@options.daemonize
        }
      end

      def mkdirs
        FileUtils.mkdir_p pid_dir
        FileUtils.mkdir_p log_dir
      end

      def log_dir
        "#{app_root}/log"
      end

      def pid_dir
        "#{app_root}/tmp/pids"
      end

      def start_script_name
        File.basename($0)
      end

      def app_root
        start_dir = File.expand_path(File.dirname($0))
        root_rel = ""
        root_rel = ".." if start_dir.end_with?("/lib") || start_dir.end_with?("/bin")
        File.expand_path(File.join(File.dirname($0), root_rel))
      end

    end

  end
end
