module Minus5
  module Daemon

    class Base

      def initialize(options, logger) 
        @options = options           
        @logger = logger
      end      

      attr_reader :logger            

      def on_start            
        logger.debug "on_start"
      end

      def run_loop               
        logger.debug "run_loop"
      end   

      def on_stop
        logger.debug "on_stop"
      end

    end   
    
  end
end
