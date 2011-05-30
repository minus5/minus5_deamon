#core lib
require 'fileutils'
require 'optparse'
require 'logger'
require 'ostruct'
#gems
require 'rubygems'
require 'active_support/core_ext'

gem 'daemons', '= 1.1.3'
require 'daemons'

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/minus5_daemon/"
require 'runner.rb'
require 'base.rb'
require 'em_base.rb'