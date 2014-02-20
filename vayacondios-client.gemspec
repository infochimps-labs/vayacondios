# coding: UTF-8

$:.push File.expand_path('../lib', __FILE__)
require 'vayacondios'

Gem::Specification.new do |gem|
  gem.name          = 'vayacondios-client'
  gem.version       = Vayacondios::GEM_VERSION
  gem.authors       = ['Philip (flip) Kromer', 'Travis Dempsey', 'Huston Hoburg', 'Logan Lowell', 'Dhruv Bansal']
  gem.homepage      = 'https://github.com/infochimps-labs/vayacondios'
  gem.email         = 'coders@infochimps.com'
  gem.licenses      = ['Apache 2.0']
  gem.summary       = 'Data goes in. The right thing happens'
  gem.description   = "Simple enough to use in a shell script, performant enough to use everywhere. Dios mío! Record that metric, ese!"

  gem.files         = `git ls-files`.split("\n").reject{ |f| f =~ /server/ }
  gem.executables   = ['vcd']
  gem.test_files    = gem.files.grep(/^spec/)
  gem.require_paths = ['lib']

  gem.add_dependency('configliere')
  gem.add_dependency('multi_json')
  gem.add_dependency('faraday',            '~> 0.8.9')
  gem.add_dependency('faraday_middleware', '~> 0.9')
end
