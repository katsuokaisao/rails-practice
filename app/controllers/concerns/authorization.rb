# frozen_string_literal: true

module Authorization
  class NotAuthorizedError < StandardError; end

  private

  def authorize_action!(record)
    policy = policy(record)
    return true if policy.public_send("#{action_name}?")

    raise NotAuthorizedError
  end

  def policy(record)
    policy_class = find_policy_class
    policy_class.new(current_actor, record)
  end

  def find_policy_class
    "#{controller_path.camelize}Policy".constantize
  end
end
