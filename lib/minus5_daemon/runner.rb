module Minus5
  module Service

    class Runner

      include SignalsHelper
      include LoggerHelper
      include OptionsHelper

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
        options.logger = @logger
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

      def on_signal_int
        logger.debug "INT signal received"
        options.active = false
        call_teardown
      end

      def call_teardown
        @teardown_block.call if @teardown_block
        @teardown_block = nil
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
