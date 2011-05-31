#!/usr/bin/env ruby
gem_file = File.join(File.expand_path(File.dirname(__FILE__)), "/../../../", "lib/minus5_daemon.rb")
File.exists?(gem_file) ? require(gem_file) : require('minus5_daemon')

class EmBase < Minus5::Daemon::EmBase

  protected

  def em_run
    @counter = 0
    EventMachine::add_periodic_timer(5) do
      logger.info "em_timer #{@counter}"
      @counter += 1
    end
  end

end

Minus5::Daemon.run EmBase