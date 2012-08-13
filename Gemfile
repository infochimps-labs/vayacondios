source 'http://rubygems.org'

gem   'yajl-ruby',       "~> 1.1"

# # TODO: swap out yajl for preferred setup:
# gem   'multi_json',  ">= 1.1"
# gem 'oj',          ">= 1.2", :platform => :ruby
# gem 'json',                  :platform => :jruby

gem   'gorillib',        :git => 'https://github.com/infochimps-labs/gorillib.git', :branch => '0.0.2'
gem   'configliere'
# gem   'wukong-flume', '0.0.2', git: 'https://github.com/infochimps/wukong-flume.git', branch: '0.0.2'

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
  gem 'bundler',     "~> 1.1"
  gem 'rake'
  gem 'yard',        ">= 0.7"
  gem 'rspec',       ">= 2.8"
  gem 'jeweler',     ">= 1.6"
end

group :docs do
  gem 'RedCloth',    ">= 4.2", :require => "redcloth"
  gem 'redcarpet',   ">= 2.1"
end

# Gems for testing and coverage
group :test do
  gem 'simplecov',   ">= 0.5", :platform => :ruby_19
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
