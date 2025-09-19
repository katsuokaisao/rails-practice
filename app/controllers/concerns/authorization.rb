# frozen_string_literal: true

module Authorization
  class NotAuthorizedError < StandardError; end

  private

  def authorize_action!(record)
    policy = policy(record)
    return true if policy.public_send("#{action_name}?")

    actor_info = if moderator_signed_in?
                   "Moderator #{current_moderator.id}"
                 elsif user_signed_in?
                   "User #{current_user.id}"
                 else
                   'Anonymous'
                 end
    action_info = "#{controller_name.classify}Controller##{action_name}"
    msg = "Authorization Failure: #{actor_info} attempted to #{action_info}"
    msg += " on Record #{record.class.name}##{record.id}" if record.present?

    Rails.logger.warn msg
    raise NotAuthorizedError
  end

  def policy(record)
    policy_class = find_policy_class
    policy_class.new(current_user, current_moderator, record)
  end

  def find_policy_class
    "#{controller_path.camelize}Policy".constantize
  end
end
