#!/usr/bin/env ruby
gem_file = File.join(File.expand_path(File.dirname(__FILE__)), "/../../../", "lib/minus5_daemon.rb")
File.exists?(gem_file) ? require(gem_file) : require('minus5_daemon')

Minus5::Service.run do 

  # add_cmd_line_options do |opts|
  #   opts.on_head("--param1", "EXIT!!!") do
  #     exit
  #   end    
  # end

  once do
    5.times do
      logger.info "process 1"
      suspend 1    
    end
  end

  once do
    5.times do
      logger.info "process 2"
      suspend 1    
    end
  end

  # every(2) do
  #   Minus5::Daemon.logger.info "process 3"
  # end

  # forever do
  #   Minus5::Daemon.options.logger.info "process 4"
  #   suspend 0.5
  # end

  # once do
  #   loop do
  #     logger.info "process 5"
  #     sleep 1
  #     Thread.current.exit unless active?
  #   end    
  # end

  every(1) do
    logger.info "process 3"
  end
  
end
