module Minus5
  module Daemon

    def self.run(&block)
      runner = Runner.new &block
      @@logger = runner.logger
    rescue => e
      print "#{e}\n#{e.backtrace}\n"
    end
    
    def self.logger
      @@logger
    end

    class Runner

      def initialize(&block)
        default_options
        init_logger
        parse_arg_options
        load_config
        load_environment_file
        mkdirs
        @processes = []
        instance_eval(&block)
        @args = @opts.parse!(ARGV)        
        start_deamon
      end

      attr_reader :logger, :options

      def add_cmd_line_options
        yield @opts
      end

      def once(&block)
        @processes << [nil, block]
      end

      def every(interval, &block)
        @processes << [interval, block]
      end

      def forever(&block)
        @processes << [0, block]
      end
      
      private

      def start_deamon
        Thread.abort_on_exception = true
        Daemons.run_proc(options.app_name, daemon_options) do
          log_start_info
          trap_signals
          @threads = []
          @processes.each do |interval, block|
            @threads << Thread.new do
              Thread.current[:id] = @threads.size
              while options.active                
                block.call(options)
                if interval
                  suspend(interval) if interval > 0
                else
                  break
                end                
              end
            end
          end
          @threads.each do |thread|             
            thread.join      
            logger.debug "thread join #{thread[:id]}"
          end
        end
      rescue Daemons::CmdException, OptionParser::ParseError => e
        print_usage e        
      end      

      def default_options
        @options = Hashie::Mash.new(
                                    :daemonize   => true,
                                    :backtrace   => false,
                                    :config_file => 'config.yml',
                                    :environment => 'production',
                                    :app_name    => start_script_name,
                                    :app_root    => app_root,
                                    :log_dir     => log_dir,
                                    :pid_dir     => pid_dir,
                                    :active      => true)
      end

      def log_start_info
        logger.info "starting daemon pid: #{Process.pid}"
      end

      def trap_signals
        Signal.trap("TERM") { stop_threads "TERM" }
        Signal.trap("INT")  { stop_threads "INT" }
      end

      def stop_threads(signal)
        logger.debug "#{signal} signal received"
        options.active = false        
        # Kernel::sleep 2
        # @threads.each do |thread|
        #   thread.kill
        # end
      end

      def load_environment_file
        file = "#{app_root}/config/#{options.environment}.yml"
        if File.exists?(file)
          options.merge!(YAML.load_file(file))
        end
      end

      def load_config
        config_file = "#{app_root}/config/#{options.config_file}"
        if File.exists?(config_file)
          options.config = Hashie::Mash.new(YAML.load_file(config_file))
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
        @logger.formatter = proc do |severity, datetime, progname, msg|
          thread_id = Thread.current[:id]
          thread = thread_id ? " [#{thread_id}]" : ""
          "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} #{severity}#{thread}: #{msg}\n"
        end
        options.logger = @logger
      end

      def parse_arg_options
        @opts = OptionParser.new do |opts|
          opts.banner = ""          
          opts.on('-n','--no-daemonize',"Don't run as a daemon") do
            @options.daemonize = false
          end
          opts.on('-e','--environment=ENVIRONMENT',"Specifies the environment for this server. Default: production") do |name|
            @options.environment = name
          end
          opts.on('-a','--app-name=name',"Use specified application name for daemon process.") do |name|
            @options.app_name = name
          end
          opts.on('-t','--backtrace',"Write crash_dump in log dir, with all exceptions in ObjectSpace on exit.") do 
            @options.backtrace = true
          end
          opts.on_tail("-h", "--help", "Show this message") do         
            print_usage									           
            exit
          end
          opts.on_tail("--version", "Show version") do
            puts "minus5_daemon version #{Minus5::Daemon::VERSION}"
            exit
          end
        end        
      end

      def print_usage(error)
        puts "ERROR: #{error.to_s}\n"
        puts <<-END
  Usage: #{@options.app_name} <options> <command>
  
  * where <options> may contain several of the following:
  #{@opts.to_s}
  
  * and <command> is one of:
  
      start         start an instance of the application 
      stop          stop all instances of the application
      restart       stop all instances and restart them afterwards
      reload        send a SIGHUP to all instances of the application
      run           start the application and stay on top
      zap           set the application to a stopped state
      status        show status (PID) of application instances
END
      end

      def daemon_options
        {
          :backtrace   => @options.backtrace,
          :dir_mode    => :normal,
          :log_output  => true,
          :dir         => pid_dir,
          :log_dir     => log_dir,
          :ARGV        => @args,
          :ontop       => !@options.daemonize,
          :environment => @options.environment
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
        return @app_root if @app_root        
        start_dir = File.expand_path(File.dirname($0))
        root_rel = ""
        root_rel = ".." if start_dir.end_with?("/lib") || start_dir.end_with?("/bin")
        @app_root = File.expand_path(File.join(File.dirname($0), root_rel))
      end

      # sleep for delay, but check at least every second if TERM signal is received
      def suspend(interval)
        if interval < 1
          Kernel::sleep interval
          return
        end
        elapsed = 0
        while @options.active && elapsed < interval
          Kernel::sleep((interval - elapsed < 1) ? (interval - elapsed) : 1)
          elapsed = elapsed + 1
        end
        unless @options.active
          logger.debug "suspend - exit thread"
          Thread.current.exit
        end
      end

    end
  end
end
