#promjena naziva log fileova
#originalni je [app_name].output, a ovo mapira na Rails standard [evironment].log
module Daemons
  class Application

    alias_method :output_logfile_orig, :output_logfile
    alias_method :logfile_orig, :logfile

    def output_logfile
      options[:output_logfile] || output_logfile_orig
    end
    
    def logfile
      options[:logfile] || logfile_orig
    end

  end
end


#iskomentirao sam ove donje tri linije u originalnoj implementaciji i propagriao gresku dalje (raise)
#hvatam je u runner.rb i tamo ispisujem usage
module Daemons
  class Controller

    def catch_exceptions(&block)
      begin
        block.call
      rescue CmdException, OptionParser::ParseError => e        
        # puts "ERROR: #{e.to_s}"
        # puts
        # print_usage()
        raise
      rescue RuntimeException => e
        puts "ERROR: #{e.to_s}"
      end
    end
    
  end
  
end
