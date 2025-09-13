# frozen_string_literal: true

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers, type: :system
  config.include Warden::Test::Helpers, type: :request

  config.before(:suite) { Warden.test_mode! }
  config.after(:each, type: :system) { Warden.test_reset! }
  config.after(:each, type: :feature) { Warden.test_reset! }
  config.after(:each, type: :request) { Warden.test_reset! }
end
