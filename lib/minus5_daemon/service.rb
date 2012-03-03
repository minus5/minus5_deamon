module Minus5
  module Service

    def self.run(&block)
      Runner.new &block
    rescue => e
      print_error_and_exit e
    end

    def self.em(&block)
      EmRunner.new &block
    rescue => e
      print_error_and_exit e
    end

    def self.print_error_and_exit(e)
      print "#{e}\n\t#{e.backtrace.join("\n\t")}\n"
      exit!      
    end

  end
end
