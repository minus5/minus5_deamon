module Minus5
  module Service

    module SignalsHelper

      private
      
      def trap_signals
        Signal.trap("TERM") { on_signal_term }
        Signal.trap("INT")  { on_signal_int }
      end
      
      def on_signal_term        
        exit!
      end

      def on_signal_int
      end

    end

  end      
end
