#!/usr/bin/env ruby
require File.join(File.expand_path(File.dirname(__FILE__)), 
  "/../../", "lib/minus5_daemon.rb")

Minus5::Service.em do 

  every(2) do
    logger.debug "calling status"
    cast :req, :status, "whats the status"
  end

  receive do |socket, action, data|    
    logger.debug "#{socket}:#{action}:#{data}"
  end
  
end
