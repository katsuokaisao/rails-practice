# frozen_string_literal: true

module Rack
  class Attack
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch('REDIS_URL', nil))

    throttle('req/ip/sign_in', limit: 5, period: 60.seconds) do |req|
      req.ip if req.path.match?(/sign_in/) && req.post?
    end

    throttle('req/ip/topics', limit: 10, period: 5.minutes) do |req|
      req.ip if req.path.match?(/topics/) && req.post?
    end

    throttle('req/ip/comments', limit: 15, period: 5.minutes) do |req|
      req.ip if req.path.match?(/comments/) && req.post?
    end

    throttle('req/ip/reports', limit: 5, period: 5.minutes) do |req|
      req.ip if req.path.match?(/reports/) && req.post?
    end

    throttle('req/user/contents', limit: 30, period: 10.minutes) do |req|
      user_id = req.env['warden']&.user&.id
      user_id if user_id && req.path.match?(/topics|comments|reports/) && (req.post? || req.put? || req.patch?)
    end

    self.throttled_response = lambda do |env|
      match_data = env['rack.attack.match_data']
      now = match_data[:epoch_time]
      retry_after = (match_data[:period] - (now % match_data[:period])).to_i

      headers = {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      }

      [429, headers, [{ error: 'レート制限を超えました。しばらく待ってから再試行してください。' }.to_json]]
    end
  end
end
