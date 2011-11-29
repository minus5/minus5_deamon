module Minus5
  module Service

    def self.run(&block)
      Runner.new &block
    rescue => e
      print "#{e}\n#{e.backtrace}\n"
      pp e.backtrace
      exit! false
    end

    class Runner

      def initialize(&block)
        @processes = []
        @threads = []
        init
        instance_eval(&block)
        start
      end

      attr_reader :logger, :options

      def add_command_line_arguments
        yield @opts
      end

      def once(&block)
        add_process({:interval => nil, :block => block})
      end

      def every(interval, &block)
        add_process({:interval => interval, :block => block})
      end

      def forever(&block)
        add_process({:interval => 0, :block => block})
      end

      def active?
        options.active
      end

      def run_controller(klass, interval, start_options)
        add_process({:klass => klass, :interval => interval, :start_options => start_options})
      end

      def touch_file(path)
        FileUtils.touch path
      end

      def setup(&block)
        @setup_block = block
      end

      def teardown(&block)
        @teardown_block = block
      end

      private

      def add_process(params)
        @processes << Hashie::Mash.new(params)
      end

      def init
        default_options
        init_logger
        init_command_line_arguments
      end

      def start
        parse_command_line_arguments
        load_config_file

        @setup_block.call if @setup_block

        trap_signals
        logger.info "starting"
        start_threads
        logger.info "started"
        join_threads
        logger.info "stopped"
      rescue OptionParser::ParseError => e
        print_usage e
      end

      def start_threads
        Thread.abort_on_exception = true
        thread_id = 0
        @processes.each do |process|
          @threads << Thread.new do
            Thread.current[:id] = (thread_id = thread_id + 1)
            if process.block
              exec_block process
            elsif process.klass
              exec_controller process
            end
          end
        end
      end

      def exec_controller(process)
        controller = process.klass.new(process.start_options.merge(options))
        logger.debug "#{controller.name} started"
        while active? && controller.active?
          controller.run
          suspend(process.interval) if controller.empty?
        end
        logger.debug "#{controller.name} finished"
      end

      def exec_block(process)
        while active?
          process.block.call(process.options)
          break                     if process.interval.nil?
          suspend(process.interval) if process.interval > 0
        end
        #call_teardown if @threads.size == 1
      end

      def join_threads
        @threads.each do |thread|
          thread.join
        end
      end

      def default_options
        @cmd_options = Hashie::Mash.new(:config   => 'config')
        @options = Hashie::Mash.new(
                                    :app_root => app_root,
                                    :active   => true)
      end

      def trap_signals
        Signal.trap("TERM") { signal_received "TERM" }
        Signal.trap("INT")  { signal_received "INT" }
      end

      def signal_received(signal)
        logger.debug "#{signal} signal received"
        options.active = false
        call_teardown
      end

      def call_teardown
        @teardown_block.call if @teardown_block
        @teardown_block = nil
      end

      def load_config_file
        file = "#{app_root}/config/#{@cmd_options.config}.yml"
        @options.merge!(YAML.load_file(file)) # if File.exists?(file)
        @options.merge!(@cmd_options)
      end

      def init_logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
        @logger.datetime_format = "%H:%M:%S"
        pid = Process.pid
        @logger.formatter = proc do |severity, datetime, progname, msg|
          time = datetime.strftime("%Y-%m-%d %H:%M:%S")
          head = "%s %-5s [%5d-%02d]: %s\n" % [time, severity, pid, Thread.current[:id] || 0 , msg]
        end
        options.logger = @logger
        $stdout.sync = true
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
          Thread.current.exit
        end
      end

    end
  end
end
