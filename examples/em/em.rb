#!/usr/bin/env ruby
require File.join(File.expand_path(File.dirname(__FILE__)), 
  "/../../", "lib/minus5_daemon.rb")

Minus5::Service.em do 

  setup do 
    logger.debug "setup..."
  end

  teardown do
    logger.debug "teardown..."
  end
  
  run do
    pp options
    logger.debug "run..."
  end

  every(1) do 
    logger.debug "every 1 second"
  end

  every(2) do 
    logger.debug "every 2 seconds"
  end

  command_options do |p|
    p.banner  = "iso medo u ducan"
    p.version = "0.01"
    p.option :arg1, "sample argument", :default => "arg1"
  end

end
