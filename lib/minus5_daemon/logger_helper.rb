module Minus5
  module Service

    module LoggerHelper

      attr_reader :logger

      private

      def init_logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
        @logger.datetime_format = "%H:%M:%S"
        pid = Process.pid
        @logger.formatter = proc do |severity, datetime, progname, msg|
          time = datetime.strftime("%Y-%m-%d %H:%M:%S.%L")
          head = "%s %-5s [%5d-%02d]: %s\n" % [time, severity, pid, Thread.current[:id] || 0 , msg]
        end
        $stdout.sync = true
      end

    end
  end
end
