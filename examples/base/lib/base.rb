#!/usr/bin/env ruby
gem_file = File.join(File.expand_path(File.dirname(__FILE__)), "/../../../", "lib/minus5_daemon.rb")
File.exists?(gem_file) ? require(gem_file) : require('minus5_daemon')

class Base < Minus5::Daemon::Base

  def on_start
    @counter = 0
    @sleep_interval = 5
  end

  def run_loop
    logger.info "run_loop #{@counter}"
    @counter += 1
  end

end

Minus5::Daemon::run Base