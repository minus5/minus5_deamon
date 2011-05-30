require 'rake'

GEMSPEC = Gem::Specification.new do |spec| 

  spec.name = 'minus5_daemons' 
  spec.summary = "minus5 daemons lib" 
  spec.version = File.read('VERSION').strip
  spec.author = 'Igor Anic' 
  spec.email = 'ianic@minus5.hr'
  
  spec.add_dependency('daemons'      , '~> 1.1.3')
  spec.add_dependency('activesupport', '~> 3.0.7')
  
  spec.files = FileList['lib/*', 'lib/**/*', 'tasks/*' , 'bin/*', 'test/*','test/**/*', 'Rakefile'].to_a  

  spec.homepage = 'http://www.minus5.hr' 
  spec.test_files = FileList['test/*_test.rb'].to_a
  
  spec.description = <<-EOF
  minus5_daemons is a simple lib for crating Ruby daemons
  it is built on top daemons.rb (http://daemons.rubyforge.org/)
  EOF
end
