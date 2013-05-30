# -*- ruby -*-

require 'bundler' ; Bundler.setup

require 'configliere'

# App-specific tasks
Dir[File.dirname(__FILE__)+'/lib/tasks/**/*.rake'].sort.each{|f| load f }

task :default => :spec
