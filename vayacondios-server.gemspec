# -*- encoding: utf-8 -*-

$:.push File.expand_path('../lib', __FILE__)
require 'vayacondios'

Gem::Specification.new do |gem|
  gem.name          = 'vayacondios-server'
  gem.version       = Vayacondios::GEM_VERSION
  gem.authors       = ['Philip (flip) Kromer', 'Travis Dempsey', 'Huston Hoburg', 'Logan Lowell']
  gem.homepage      = 'https://github.com/infochimps-labs/vayacondios'
  gem.email         = 'coders@infochimps.com'
  gem.licenses      = ['Apache 2.0']
  gem.summary       = 'Data goes in. The right thing happens'
  gem.description   = "Simple enough to use in a shell script, performant enough to use everywhere. Dios mío! Record that metric, ese!"

  gem.files         = `git ls-files`.split("\n")
  gem.executables   = ['vcd-server', 'vcd-clean']
  gem.test_files    = gem.files.grep(/^spec/)
  gem.require_paths = ['lib']

  gem.add_dependency('configliere',     '>= 0.4.16')
  gem.add_dependency('gorillib',        '>= 0.4.2')
  gem.add_dependency('multi_json',      '>= 1.3.6')
  gem.add_dependency('goliath-chimp',   '>= 0.0.1')

  gem.add_dependency('eventmachine',    '~> 1.0.0.beta.4')
  gem.add_dependency('goliath',         '~> 1.0')
  gem.add_dependency('em-http-request', '~> 1.0')
  gem.add_dependency('mongo')
  gem.add_dependency('em-mongo',        '~> 0.4.3')
  gem.add_dependency('bson_ext')
  gem.add_dependency('chronic_duration') # for vcd-clean
end
