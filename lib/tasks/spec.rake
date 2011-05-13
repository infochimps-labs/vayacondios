desc "Run Watchr"
task :watchr do
  sh %{bundle exec watchr .watchr}
end

desc "Run Spork"
task :spork do
  sh %{bundle exec spork rspec}
end
