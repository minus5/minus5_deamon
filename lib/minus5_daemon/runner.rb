module Minus5
  module Daemon

    def self.run(&block)
      Runner.new &block
    rescue => e
      print "#{e}\n#{e.backtrace}\n"
    end

    class << self
      attr_reader :logger, :options
    end
    
    class Runner

      def initialize(&block)
        @processes = []

        init        
        instance_eval(&block)
        start
      end

      attr_reader :logger, :options

      def add_command_line_arguments
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

      def active?
        options.active
      end

      def touch_log
        FileUtils.touch options.log_file
      end
      
      private

      def init
        default_options
        init_logger
        init_command_line_arguments
        mkdirs
      end

      def start
        parse_command_line_arguments
        load_environment_file
        options.log_file = "#{options.log_dir}/#{options.environment}.log"
        options.crash_dump_file = "#{options.log_dir}/crash_dump_#{options.environment}.log"
        start_deamon
      end

      def start_deamon
        Thread.abort_on_exception = true
        Daemons.run_proc(options.app_name, daemon_options) do
          logger.info "starting daemon pid: #{Process.pid}" if options.run_as_daemon
          trap_signals
          @threads = []
          thread_id = 0
          @processes.each do |interval, block|
            @threads << Thread.new do
              Thread.current[:id] = (thread_id = thread_id + 1)
              while active?                
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
                                    :run_as_daemon => true,
                                    :backtrace     => false,                      
                                    :environment   => 'production',
                                    :app_name      => start_script_name,
                                    :app_root      => app_root,
                                    :log_dir       => "#{app_root}/log",
                                    :pid_dir       => "#{app_root}/tmp/pids",
                                    :active        => true)
      end

      def trap_signals
        Signal.trap("TERM") { signal_received "TERM" }
        Signal.trap("INT")  { signal_received "INT" }
      end

      def signal_received(signal)
        logger.debug "#{signal} signal received"
        options.active = false        
        ##forcing thread to exit
        # @threads.each do |thread|
        #   thread.kill
        # end
      end

      def load_environment_file
        file = "#{app_root}/config/#{options.environment}.yml"
        if File.exists?(file)
          @options.merge!(YAML.load_file(file))
        end
      end

      def init_logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
        @logger.datetime_format = "%H:%M:%S"        
        @logger.formatter = proc do |severity, datetime, progname, msg|
          time = datetime.strftime("%Y-%m-%d %H:%M:%S")
          head = "%s %-5s [%3d]: %s\n" % [time, severity, Thread.current[:id] || 0 , msg]
        end
        options.logger = @logger
        #osiguraj da je logger vidljiv kako Minus5::Daemon.logger
        global_logger = @logger
        global_options = options
        Minus5::Daemon.instance_eval { @logger = global_logger }
        Minus5::Daemon.instance_eval { @options = global_options }
      end

      def parse_command_line_arguments
        @args = @opts.parse!(ARGV)
      end

      def init_command_line_arguments
        @opts = OptionParser.new do |opts|
          opts.banner = ""          
          opts.on('-n','--no-daemonize',"Don't run as a daemon") do
            @options.run_as_daemon = false
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

      def print_usage(error = nil)
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
          :backtrace      => options.backtrace,
          :dir_mode       => :normal,
          :log_output     => true,
          :dir            => options.pid_dir,
          :log_dir        => options.log_dir,
          :ARGV           => @args,
          :ontop          => !options.run_as_daemon,
          :environment    => options.environment,
          :output_logfile => options.log_file,
          :logfile        => options.crash_dump_file
        }
      end

      def mkdirs
        FileUtils.mkdir_p options.pid_dir
        FileUtils.mkdir_p options.log_dir
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

      # sleep for delay, but check at least every second if exit signal is received
      def suspend(interval)
        if interval < 1
          Kernel::sleep interval
          return
        end
        elapsed = 0
        while active? && elapsed < interval
          Kernel::sleep((interval - elapsed < 1) ? (interval - elapsed) : 1)
          elapsed = elapsed + 1
        end
        unless active?
          logger.debug "suspend - exit thread"
          Thread.current.exit
        end
      end

    end
  end
end
