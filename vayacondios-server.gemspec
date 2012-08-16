# -*- encoding: utf-8 -*-

$:.push File.expand_path('../lib', __FILE__)
require 'vayacondios/version'

Gem::Specification.new do |gem|
  gem.name          = 'vayacondios'
  gem.version       = Vayacondios::VERSION
  gem.authors       = ['Philip (flip) Kromer', 'Travis Dempsey', 'Huston Hoburg']
  gem.homepage      = 'https://github.com/infochimps-labs/vayacondios'
  gem.summary       = 'Data goes in. The right thing happens'
  gem.description   = <<DESC
                                                                                                                                 
Simple enough to use in a shell script, performant enough to use everywhere. Why the hell wouldn't you record that metric, ese?

* Server code 

DESC

  gem.files         = `git ls-files`.split("\n")
  gem.executables   = []
  gem.test_files    = gem.files.grep(/^spec/)
  gem.require_paths = ['lib']

  gem.add_dependency('configliere',     '>= 0.4.13')
  gem.add_dependency('yajl-ruby',       '~> 1.1')
  gem.add_dependency('goliath',         '~> 0.9.2')
  gem.add_dependency('em-http-request', '~> 1.0')
  gem.add_dependency('em-mongo',        '~> 0.4.2')
  gem.add_dependency('bson_ext',        '~> 1.6')
  gem.add_dependency('gorillib',        '0.4.0pre')
  gem.add_dependency('foreman')
end
