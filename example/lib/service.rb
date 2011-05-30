#require 'minus5_daemon'
require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/minus5_daemon.rb"

class Service < Minus5::Daemon::Base
  
  def on_start
    @counter = 0
  end
  
  def run_loop
    logger.info "run_loop #{@counter}"
    @counter += 1
  end
  
end