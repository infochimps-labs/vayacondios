source "http://rubygems.org"

gem   'yajl-ruby',       "~> 1.1"
gem   'gorillib',        :git => 'https://github.com/infochimps-labs/gorillib.git', :branch => '7a995126e2fbe6b6ddcdf04866937d43b3376b1b'
gem   'configliere'

gem   'goliath',         :git => 'https://github.com/postrank-labs/goliath.git'
gem   'eventmachine',    :git => 'https://github.com/eventmachine/eventmachine.git'
gem   'em-synchrony',    "~> 1.0"
gem   'em-http-request', "~> 1.0"

gem   'em-mongo',        "~> 0.4.2"
gem   'bson_ext',        "~> 1.6"

gem   'foreman'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem 'bundler',   "~> 1"
  gem 'jeweler',   "~> 1.6"
  gem 'rspec',     "~> 2.9"
  gem 'yard',      "~> 0.6"
  gem 'pry'
end

group :test do
  gem 'spork',           "~> 0.9.0"
  gem 'guard',         "~> 1"
  gem 'guard-rspec'
  gem 'guard-yard'
end
