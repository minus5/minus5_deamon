require "rake/testtask"
require 'rubygems/package_task'
load 'minus5_daemon.gemspec'

task :default => [:test]

Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = Dir[ "test/test_*.rb" ]
  test.verbose = true
end

Gem::PackageTask.new(GEMSPEC) do |pkg|
end

desc "build gem and deploy to gems.minus5.hr"
task :deploy => [:gem] do
  file = "pkg/minus5_daemon-#{GEMSPEC.version}.gem"
  print "installing\n"
  `gem install #{file} --no-rdoc --no-ri`
  # print "copying to gems.minus5.hr\n"
  # `scp #{file} gems.minus5.hr:/var/www/apps/gems/gems`
  # print "updating gem server index\n"
  # `ssh ianic@gems.minus5.hr "cd /var/www/apps/gems; sudo gem generate_index"`
  print "copying to korana.s.minus5.hr\n"
  `scp #{gem_file} korana.s.minus5.hr:/var/www/gems.minus5.hr/gems`
  print "updating gem server index\n"
  `ssh korana.s.minus5.hr "cd /var/www/gems.minus5.hr; sudo gem generate_index"`
end

task :pero do
  file = "pkg/minus5_daemon-#{GEMSPEC.version}.gem"
  print "scp #{file} gems.minus5.hr:/var/www/apps/gems/gems"
end
