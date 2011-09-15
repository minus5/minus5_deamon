#core lib
require 'fileutils'
require 'optparse'
require 'logger'
require 'ostruct'
require 'yaml'
require 'pp'
#gems
require 'rubygems'
require "bundler/setup"

gem 'daemons', '= 1.1.4'
require 'daemons'
require 'hashie'

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/minus5_daemon/"
require 'runner.rb'
require 'daemons_patch.rb'
require 'service.rb'

module Minus5
  module Daemon
    VERSION = File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).strip
  end
end
