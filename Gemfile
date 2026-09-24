source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.9'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.2.3', '>= 7.2.3.2'
# Use Puma as the app server
gem 'puma', '>= 5.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 6.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.15'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Ruby 3.4+ compatibility gems
gem 'ostruct'
gem 'mutex_m'

# Transitive via rdoc; pinned for CVE-2026-41316
gem 'erb', '>= 6.0.4'

# Hold the 0.5 API for EmailSyncService; 0.5.15 carries the CVE fixes
gem 'net-imap', '~> 0.5.15'

gem 'sprockets-rails'
gem 'bootstrap', '~> 4.5'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem "bootstrap_form", ">= 4.5.0"

gem 'inline_svg'

gem 'pg'

gem 'jquery-datatables'
gem 'ajax-datatables-rails'

group :development, :test do
  # Call 'debugger' anywhere in the code to stop execution and get a console.
  # bin/dev already exports RUBY_DEBUG_OPEN/RUBY_DEBUG_LAZY for this.
  gem 'debug', require: false
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'

  gem 'faker'
end

group :test do
  # Intentionally left empty - using lightweight integration tests only
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:windows, :jruby]

gem "tailwindcss-rails", "~> 3.0"
