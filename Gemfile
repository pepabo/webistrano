source "https://rubygems.org"

gem "rails", '3.2.13'

gem "exception_notification"

gem "capistrano"
gem "open4"
gem "syntax"
gem "version_fu", :git => "https://github.com/jmckible/version_fu.git"
gem "devise", "3.0.3"
gem "devise-encryptable"
gem "pg"

gem 'rvm-capistrano'
gem 'capistrano-rbenv'
gem 'capistrano-unicorn', :require => false, :git => 'https://github.com/sosedoff/capistrano-unicorn.git'
gem 'whenever', :require => false

group :development do
  gem "thin"

  gem "debugger"
  gem "pry"
  gem "pry-rails"
end

group :test do
  gem "mocha", :require => false
  gem "factory_girl_rails"
  gem "database_cleaner"
  gem 'minitest-reporters'
end

group :production do
  gem "unicorn"
end

group :assets do
  gem "jquery-rails"
  gem "uglifier"
  gem 'therubyracer'
end

if File.exists?('config/Gemfile.extras')
  eval File.read('config/Gemfile.extras')
end
