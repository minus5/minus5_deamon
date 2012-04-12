#!/usr/bin/env ruby
require File.join(File.expand_path(File.dirname(__FILE__)), 
  "/../../", "lib/minus5_daemon.rb")

Minus5::Service.em do 

  every(1) do 
    msg = Time.now
    logger.debug "server: pub time #{msg}"
    publish :pub, :time, msg
  end

  receive do |socket, action, data, headers|
    logger.debug "server: #{socket}:#{action}:#{data}" 
    "status is ok"
  end
  
end
