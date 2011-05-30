#!/usr/bin/env ruby         
#require 'minus5_daemons'
require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/minus5_daemons.rb"

Minus5::Daemon.run
