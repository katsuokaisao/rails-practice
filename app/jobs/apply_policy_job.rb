# frozen_string_literal: true

class ApplyPolicyJob < ApplicationJob
  queue_as :default

  def perform(tenant_id, changed_policies)
    tenant = Tenant.find(tenant_id)

    ActiveRecord::Base.transaction do
      tenant.apply_topic_policy if changed_policies.include?(:topic)

      tenant.apply_comment_policy if changed_policies.include?(:comment)
    end

    tenant.status_idle!
  rescue StandardError => e
    tenant = Tenant.find(tenant_id)
    tenant.status_failed!

    Rails.logger.error("ApplyPolicyJob failed for tenant #{tenant_id}: #{e.message}")
    raise
  end
end
