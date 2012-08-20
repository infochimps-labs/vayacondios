require 'bundler' ; Bundler.setup

# App-specific tasks
Dir[File.dirname(__FILE__)+'/lib/tasks/**/*.rake'].sort.each{|f| load f }

task :default => :spec
