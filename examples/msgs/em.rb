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
    logger.debug "run..."
  end

  receive do |socket, action, body, headers|
    logger.debug "receive action: #{action}, version: #{headers.version}, body: #{!body.nil?} socket: #{socket}, headers: #{headers.inspect}"
    unless body.nil?
      logger.debug body
    end
  end

end
