# frozen_string_literal: true

module UnsubscriptionHelper
  def unsubscribed_user_policy_description(tenant)
    {
      comment: t("unsubscription.policy_descriptions.comment.#{tenant.unsubscribed_user_comment_policy}"),
      topic: t("unsubscription.policy_descriptions.topic.#{tenant.unsubscribed_user_topic_policy}")
    }
  end

  def unsubscribed_user_policy_label(policy_type, policy_value)
    t("unsubscription.policy_labels.#{policy_type}.#{policy_value}")
  end

  def unsubscribed_user_policy_options(type)
    case type
    when :comment
      Tenant.unsubscribed_user_comment_policies.keys.map do |key|
        [t("unsubscription.policy_labels.comment.#{key}"), key]
      end
    when :topic
      Tenant.unsubscribed_user_topic_policies.keys.map do |key|
        [t("unsubscription.policy_labels.topic.#{key}"), key]
      end
    end
  end
end
