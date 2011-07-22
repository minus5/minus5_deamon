module Minus5
  module Daemon

    class Base

      def initialize(options, logger)
        @options = options
        @logger = logger
        @active = true
        @sleep_interval = 1
      end

      attr_reader   :logger

      def run
        on_start
        Signal.trap("TERM") do
          logger.debug "TERM signal received"
          @active = false
        end
        Signal.trap("INT") do
          logger.debug "INT signal received"
          @active = false        
        end
        if self.respond_to?(:run_loop)
          while @active
            run_loop
            sleep_with_check
          end
        end
      end

      protected

      # sleep for delay, but check at least every second if TERM signal is received
      def sleep_with_check
        if @sleep_interval < 1
          Kernel::sleep @sleep_interval
          return
        end
        elapsed = 0
        while @active && elapsed < @sleep_interval
          Kernel::sleep((@sleep_interval - elapsed < 1) ? (@sleep_interval - elapsed) : 1)
          elapsed = elapsed + 1
        end
      end

      def on_start
        logger.debug "on_start"
      end

      # def run_loop
      #   logger.debug "run_loop"
      # end

      def on_stop
        logger.debug "on_stop"
      end

    end

  end
end
