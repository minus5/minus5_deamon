#!/usr/bin/env ruby         
#require 'minus5_daemon'
require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/minus5_daemon.rb"

Minus5::Daemon::Runner.run