source 'http://rubygems.org'

gemspec name: 'vayacondios-client'
gemspec name: 'vayacondios-server'

group :development do
  gem 'rake'
  gem 'yard',        ">= 0.7"
  gem 'rspec',       ">= 2.8"
end

group :docs do
  gem 'RedCloth',    ">= 4.2",   :require => "redcloth"
  gem 'redcarpet',   ">= 2.1",   :platform => [:mri, :rbx]
  gem 'kramdown',                :platform => :jruby
end

# Gems for testing and coverage
group :test do
  gem 'simplecov', :require => false
end

# Gems you would use if hacking on this gem (rather than with it)
group :support do
  gem 'pry'
  gem 'guard',       ">= 1.0"
  gem 'guard-rspec', ">= 0.6"
  gem 'guard-yard'
  if RUBY_PLATFORM.include?('darwin')
    gem 'rb-fsevent', ">= 0.9"
  end
end
