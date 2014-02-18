require 'rspec/core/rake_task'

namespace :spec do

  desc 'Run client RSpec code examples'
  RSpec::Core::RakeTask.new(:client) do |t|
    t.pattern = 'spec/client/**/*_spec.rb'
  end
  
  desc 'Run server RSpec code examples'
  RSpec::Core::RakeTask.new(:server) do |t|
    t.pattern = 'spec/server/**/*_spec.rb'
  end
end

desc 'Run both client and server Rspec code examples'
RSpec::Core::RakeTask.new

desc 'Run spec tests with simplecov'
task :coverage do
  ENV['VAYACONDIOS_COV'] = 'true'
  Rake::Task[:spec].invoke
end

def with_background_process(cmd, options = {}, &blk)
  pr = spawn cmd
  puts "waiting for command #{cmd} to execute fully"
  sleep(options[:wait]) if options[:wait]
  blk.call
ensure 
  Process.kill('KILL', pr)
  Process.wait pr
end

desc 'Run spec coverage with mongo'
task :mongo do
  # with_background_process('mongod') do
  ENV['WITH_MONGO'] = 'true'
  Rake::Task[:spec].invoke
  # end
end

desc 'Run integration tests'
task :integration do
  # with_background_process('mongod') do
  with_background_process('bin/vcd-server -e test', wait: 2) do
    Rake::Task[:features].invoke
  end
  # end
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features)

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', '-', 'CHANGELOG.md', 'LICENSE.md']
  t.options = ['--readme=README.md', '--markup=markdown', '--verbose']
end

require 'vayacondios'
Dir['*.gemspec'].each do |gemspec|
  gem_name = gemspec.gsub(/\.gemspec/, '')

  namespace :build do
    desc "Build #{gem_name} gem into the pkg directory"
    task gem_name do
      system "gem build #{gemspec}"
      FileUtils.mkdir_p('pkg')
      FileUtils.mv(Dir['*.gem'], 'pkg')
    end
  end

  namespace :release do
    desc "Tags version, pushes to remote, and pushes #{gem_name} gem"
    task gem_name => "build:#{gem_name}" do
      sh 'git', 'tag', '-m', "releasing #{gem_name}", "#{gem_name}-v#{Vayacondios::GEM_VERSION}"
      branch = `git branch | awk -F '/* ' '{print $2}'`.strip
      sh "git push origin #{branch}"
      sh "git push origin #{gem_name}-v#{Vayacondios::GEM_VERSION}"
      sh "ls pkg/#{gem_name}*.gem | xargs -n 1 gem push"
    end
  end
end

desc 'Build both gems'
task build:   ['build:vayacondios-client', 'build:vayacondios-server']

desc 'Release both gems'
task release: ['release:vayacondios-client', 'release:vayacondios-server']

task default: [:mongo, :integration]

