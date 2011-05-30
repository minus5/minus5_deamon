module Minus5

  class Daemon
    
    def self.run()
      Daemon.new.run
    end
    
    def initialize
      #super(self.class) 
      require_service_file
      @options = OpenStruct.new(
        :daemonize => true, 
        :config => nil, 
        :environment => 'production', 
        :app_name => start_script_name,
        :app_root => app_root)
      parse_arg_options                              
      init_logger
    end   
    
    attr_reader :logger

    def run
      mkdirs
      Daemons.run_proc(@options.app_name, daemon_options) do    
        logger.info "starting daemon pid: #{Process.pid}"
        logger.debug "options: #{@options}"
        service = service_class.new(@options, @logger)
        service.on_start if service.respond_to?(:on_start)
        @terminate = false
        Signal.trap("TERM") do
          @terminate = true                             
          service.on_stop if service.respond_to?(:on_stop)
        end                        
        while !@terminate
          service.run_loop
          sleep(1) 
        end                         
      end
    end

    private                                
    
    def init_logger
      @logger = Logger.new(STDOUT) 
      @logger.level = Logger::DEBUG 
      @logger.datetime_format = "%H:%M:%S" 
      @logger.formatter = proc { |severity, datetime, progname, msg|
          "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} #{severity}: #{msg}\n"
        }
    end
    
    def service_class           
      eval(start_script_name.split(".")[0].camelize)
    end

    def parse_arg_options    
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{start_script_name} [options]"
        opts.separator ''
        opts.on('-n','--no-daemonize',"Don't run as a daemon") do
          @options.daemonize = false
        end
        opts.on('-e','--environment=name',"Specifies the environment to run this server under. Default: production") do |name|
          @options.environment = name
        end
        opts.on('-c','--config=file',"Use specified config file.") do |file|
          @options.config = file
        end
        opts.on('-a','--app-name=file',"Use specified application name for daemon process.") do |name|
          @options.app_name = name
        end      
      end
      @args = opts.parse!(ARGV)    
    end

    def daemon_options
      {
        :backtrace  => true,
        :dir_mode   => :normal,
        :log_output => true,
        :dir        => pid_dir,               
        :log_dir    => log_dir,
        :ARGV       => @args, 
        :ontop      => !@options.daemonize
      }                                 
    end  

    def mkdirs                                  
      FileUtils.mkdir_p pid_dir
      FileUtils.mkdir_p log_dir
    end

    def log_dir                   
      "#{app_root}/log"
    end                       

    def pid_dir
      "#{app_root}/tmp/pids"
    end

    def start_script_name 
      File.basename($0)
    end                                                    

    def app_root 
      File.expand_path(File.dirname($0) + "/../")
    end                                        
    
    def require_service_file
      require "#{app_root}/lib/#{start_script_name}"
    end
    
  end                                    
  
end
