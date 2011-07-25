require 'rake'

GEMSPEC = Gem::Specification.new do |spec|

  spec.name = 'minus5_daemon'
  spec.summary = "minus5 daemon library"
  spec.version = File.read('VERSION').strip
  spec.author = 'Igor Anic'
  spec.email = 'ianic@minus5.hr'

  spec.add_dependency('daemons', '~> 1.1.4')
  spec.add_dependency('hashie' , '~> 1.0.0')
  spec.add_dependency('eventmachine' , '~> 0.12.10')

  spec.files = FileList['lib/*', 'lib/**/*', 'tasks/*' , 'bin/*', 'test/*','test/**/*', 'Rakefile', 'VERSION'].to_a

  spec.homepage = 'http://www.minus5.hr'
  spec.test_files = FileList['test/*_test.rb'].to_a

  spec.description = <<-EOF
  minus5_daemon is a simple lib for crating Ruby daemons
  it is built on top daemons.rb (http://daemons.rubyforge.org/)
  EOF
end
