module Minus5
  module Service

    class EmRunner

      include SignalsHelper
      include LoggerHelper
      include ZmqHelper

      def initialize(&block)
        @processes = []
        trap_signals      
        init_logger

        instance_eval(&block)
        @options = OptionsParser.new(&@command_options_block).options

        EM.epoll
        EM.run do
          zmq_init
          @setup_block.call if @setup_block
          @run_block.call if @run_block
          @processes.each do |process|
            EM.add_periodic_timer(process.interval) do
              process.block.call
            end
          end
        end
      end

      attr_reader :options

      def setup(&block)
        @setup_block = block
      end

      def teardown(&block)
        @teardown_block = block
      end

      def run(&block)
        @run_block = block
      end

      def every(interval, &block)
        add_process({:interval => interval, :block => block})
      end

      def command_options(&block)
        @command_options_block = block
      end

      def receive(&block)
        @receive_proc = block
      end

      private

      def add_process(params)
        @processes << Hashie::Mash.new(params)
      end

      def on_signal_int
        @teardown_block.call if @teardown_block
        EM.stop_event_loop
        EM.stop
      end

    end

  end
end
