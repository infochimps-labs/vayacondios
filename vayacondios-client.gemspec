# -*- encoding: utf-8 -*-

$:.push File.expand_path('../lib', __FILE__)
require 'vayacondios/version'

Gem::Specification.new do |gem|
  gem.name          = 'vayacondios-client'
  gem.version       = Vayacondios::VERSION
  gem.authors       = ['Philip (flip) Kromer', 'Travis Dempsey', 'Huston Hoburg', 'Logan Lowell']
  gem.homepage      = 'https://github.com/infochimps-labs/vayacondios'
  gem.summary       = 'Data goes in. The right thing happens'
  gem.description   = "Simple enough to use in a shell script, performant enough to use everywhere. Dios mío! Record that metric, ese!"

  gem.files         = `git ls-files -- lib  | grep client`.split("\n")
  gem.test_files    = `git ls-files -- spec | grep client`.split("\n")
  gem.require_paths = ['lib']

  gem.add_dependency('configliere', '>= 0.4.16')
  gem.add_dependency('multi_json',  '~> 1.1')
  # Gorillib versioning is borked
  gem.add_dependency('gorillib',    '0.4.0pre')

  gem.add_development_dependency('rake')
  gem.add_development_dependency('yard', '>= 0.7')
  gem.add_development_dependency('rspec', '>= 2.8')
  gem.add_development_dependency('cucumber', '~> 1.2')
end
