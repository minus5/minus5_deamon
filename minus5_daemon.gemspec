require 'rake'

GEMSPEC = Gem::Specification.new do |spec|

  spec.name = 'minus5_daemon'
  spec.summary = "minus5 services"
  spec.version = File.read('VERSION').strip
  spec.author = 'Igor Anic'
  spec.email = 'ianic@minus5.hr'

  spec.add_dependency('hashie')

  spec.files = FileList['lib/*', 'lib/**/*', 'tasks/*' , 'bin/*', 'test/*','test/**/*', 'Rakefile', 'VERSION'].to_a

  spec.homepage = 'http://www.minus5.hr'
  spec.test_files = FileList['test/*_test.rb'].to_a

  spec.description = <<-EOF

  EOF
end
