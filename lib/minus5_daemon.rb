#core lib
require 'fileutils'
require 'optparse'
require 'logger'
require 'ostruct'
require 'yaml'
#gems
require 'rubygems'

gem 'daemons', '= 1.1.4'
require 'daemons'
require 'hashie'

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/minus5_daemon/"
require 'runner.rb'
require 'base.rb'
require 'em_base.rb'
