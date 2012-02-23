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
require 'hashie'

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/minus5_daemon/"
require 'service.rb'
