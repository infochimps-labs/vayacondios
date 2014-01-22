source 'https://rubygems.org'

# em-mongo is too loose with its dependencies; 2.0.0 bson breaks vcd
gem 'bson', '1.9.2'

gemspec name: 'vayacondios-server'
gemspec name: 'vayacondios-client'

group :development do
  gem 'rake'
  gem 'foreman'
  gem 'yard'
  gem 'redcarpet'
end

group :test do
  gem 'rspec'
  gem 'simplecov'
  gem 'mongo'
  gem 'timecop'
  gem 'cucumber'
end
