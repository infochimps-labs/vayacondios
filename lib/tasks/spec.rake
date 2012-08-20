desc "Run Watchr"
task :watchr do
  sh %{bundle exec watchr .watchr}
end

namespace :spec do
  RSpec::Core::RakeTask.new :coverage do
    ENV['COVERAGE'] = "true"
  end
end