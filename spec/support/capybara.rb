# frozen_string_literal: true

require 'capybara/rspec'
require 'capybara/playwright'

Capybara.register_driver(:playwright_custom) do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium, # :chromium (default) or :firefox, :webkit
    default_navigation_timeout: 90,
    viewport: { width: 1400, height: 4000 } # Set the viewport size to capture full page screenshots
  )
end

# for debugging test codes
Capybara.register_driver(:playwright_no_headless) do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium, # 利用するブラウザの指定
    headless: false, # ヘッドレスモードで実行するかどうかの指定
    default_navigation_timeout: 90
  )
end

Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.default_driver = :playwright_custom
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :playwright_custom
  end
end
