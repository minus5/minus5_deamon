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
#TODO promjenio ovo tako da load gem tocno odredjeni, napravi bundle
# daemons_lib_dir = "../../tools/daemons-1.1.3/lib"
# $LOAD_PATH.unshift daemons_lib_dir
# require "daemons.rb"

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/minus5_daemons/" 
require 'daemon.rb'
require 'daemon_base.rb'