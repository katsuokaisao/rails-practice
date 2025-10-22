# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.3.7'

gem 'bootsnap', require: false
gem 'counter_culture', '~> 3.2'
gem 'devise'
gem 'jsbundling-rails', '~> 1.3'
gem 'mysql2', '~> 0.5'
gem 'puma', '>= 5.0'
gem 'rack-attack'
gem 'rails', '~> 8.0.0'
gem 'rails-i18n'
gem 'redis', '~> 4.6.0'
gem 'ridgepole'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[windows jruby]

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows]
  gem 'erb_lint', require: false
  gem 'factory_bot_rails'
  gem 'faker'
end

group :test do
  gem 'capybara'
  gem 'capybara-playwright-driver'
  gem 'rspec-rails'
  gem 'simplecov', require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  gem 'i18n-tasks'
  gem 'rails-erd'
  gem 'rubocop', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false

  gem 'brakeman', require: false
  gem 'bullet'
  gem 'bundler-audit', require: false

  gem 'annotaterb'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end
