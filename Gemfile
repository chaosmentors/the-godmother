source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.11'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 8.0.5', '>= 8.0.5.1'
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

# Bundled gem since Ruby 3.4 - must be declared or `require "csv"` in
# SettingsController/GroupsController raises LoadError at runtime
gem 'csv'

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

  # Rails 8.0 dropped railties' `minitest < 6` ceiling, so minitest 6 arrives
  # transitively. Held at 5.x for the duration of the Rails upgrade: the suite
  # is the only instrument verifying each step, so it should not change major
  # version in the same commits it is being used to validate. Revisit after 8.1.
  gem 'minitest', '~> 5.27'
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
