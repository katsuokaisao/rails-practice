# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :request) do
    # テスト用にメモリストアを使用
    memory_store = ActiveSupport::Cache::MemoryStore.new
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = memory_store

    config.after(:each, type: :request) do
      Rack::Attack.cache.store = original_store
    end
  end
end
