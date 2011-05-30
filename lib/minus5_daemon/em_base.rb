require 'rubygems'
require 'eventmachine'

module Minus5
  module Daemon

    class EmBase

      def initialize(options, logger)
        @options = options
        @logger = logger
      end

      def run
        EventMachine.run do
          em_run
          logger.debug "em - server started"
          Signal.trap("TERM") do
            logger.debug "em - TERM signal received"
            EventMachine::stop_event_loop
            EventMachine::stop
          end
        end
      end

      protected

      def em_run
      end

      attr_reader   :logger

    end

  end
end
