# frozen_string_literal: true

class ApplyPolicyJob < ApplicationJob
  queue_as :default

  def perform(tenant_id, changed_policies)
    tenant = Tenant.find(tenant_id)

    ActiveRecord::Base.transaction do
      tenant.apply_topic_policy if changed_policies.include?(:topic)

      tenant.apply_comment_policy if changed_policies.include?(:comment)
    end

    tenant.applying_policy_idle!
  rescue StandardError
    tenant.applying_policy_failed!
    raise
  end
end
