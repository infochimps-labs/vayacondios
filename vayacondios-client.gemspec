# -*- encoding: utf-8 -*-

$:.push File.expand_path('../lib', __FILE__)
require 'vayacondios/version'

Gem::Specification.new do |gem|
  gem.name          = 'vayacondios-client'
  gem.version       = Vayacondios::VERSION
  gem.authors       = ['Philip (flip) Kromer', 'Travis Dempsey', 'Huston Hoburg', 'Logan Lowell', 'Dhruv Bansal']
  gem.homepage      = 'https://github.com/infochimps-labs/vayacondios'
  gem.summary       = 'Data goes in. The right thing happens'
  gem.description   = "Simple enough to use in a shell script, performant enough to use everywhere. Dios mío! Record that metric, ese!"

  gem.files         = `git ls-files -- lib  | grep client`.split("\n")
  gem.test_files    = `git ls-files -- spec | grep client`.split("\n")
  gem.require_paths = ['lib']

  gem.add_dependency('configliere')
  gem.add_dependency('multi_json')
end
