require 'bundler'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', '-', 'CHANGELOG.md', 'LICENSE.md']
  t.options = ['--readme=README.md', '--markup=markdown', '--verbose']
end

desc 'Run spec tests with simplecov'
task :coverage do
  ENV['VAYACONDIOS_COV'] = 'true'
  Rake::Task[:spec].invoke
end

require 'vayacondios/version'

Dir['*.gemspec'].each do |gemspec|
  gem_name = gemspec.gsub(/\.gemspec/, '')

  desc "Build #{gem_name} gem into the pkg directory"
  task "build_#{gem_name}" do
    FileUtils.rm_rf('pkg')
    system "gem build #{gemspec}"
    FileUtils.mkdir_p('pkg')
    FileUtils.mv(Dir['*.gem'], 'pkg')
  end

  desc "Tags version, pushes to remote, and pushes #{gem_name} gem"
  task "release_#{gem_name}" =>  "build_#{gem_name}" do
    sh 'git', 'tag', '-m', "releasing #{gem_name}", "#{gem_name}-v#{Vayacondios::VERSION}"
    branch = `git branch | awk -F '/* ' '{print $2}'`.strip
    sh "git push origin #{branch}"
    sh "git push origin #{gem_name}-v#{Vayacondios::VERSION}"
    sh "ls pkg/#{gem_name}*.gem | xargs -n 1 gem push"
  end
end

task default: [:spec]

