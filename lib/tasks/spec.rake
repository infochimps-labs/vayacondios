require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

namespace :spec do
  # RSpec::Core::RakeTask.new :coverage do
  #   ENV['COVERAGE'] = "true"
  # end
end