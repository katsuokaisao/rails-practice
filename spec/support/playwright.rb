# frozen_string_literal: true

def with_playwright_page(&)
  Capybara.current_session.driver.with_playwright_page(&)
end

def playwright_locator(selector)
  with_playwright_page do |page|
    page.locator(selector)
  end
end

def start_tracing
  Capybara.current_session.driver.start_tracing(screenshots: true, snapshots: true, sources: true)
end

def stop_tracing(name:)
  trace_path = Rails.root.join('tmp', 'traces', "#{name.gsub(/\s/, '-').gsub(/[^-[:alnum:]]/, '_')}.zip")
  Capybara.current_session.driver.stop_tracing(path: trace_path.to_s)
end

def with_tracing(name:, &block)
  start_tracing
  block.call
ensure
  stop_tracing(name: name)
end
