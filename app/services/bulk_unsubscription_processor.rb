# frozen_string_literal: true

class BulkUnsubscriptionProcessor
  attr_reader :user, :tenant_ids

  def initialize(user, tenant_ids)
    raise ArgumentError, 'user is required' if user.blank?
    raise ArgumentError, 'tenant_ids is required' if tenant_ids.blank?

    @user = user
    @tenant_ids = Array(tenant_ids).map(&:to_i)
  end

  def execute
    tenant_ids.each do |tenant_id|
      process_tenant_unsubscription(tenant_id)
    end
  end

  private

  def process_tenant_unsubscription(tenant_id)
    tenant = Tenant.find(tenant_id)
    ActiveRecord::Base.transaction do
      record_unsubscription_history(tenant)
      apply_unsubscription_policies(tenant)
    end
  end

  def record_unsubscription_history(tenant)
    TenantUnsubscriptionHistory.create!(
      user_id: user.id,
      tenant_id: tenant.id,
      comment_policy: tenant.unsubscribed_user_comment_policy,
      topic_policy: tenant.unsubscribed_user_topic_policy,
      unsubscribed_at: Time.current
    )
  end

  def apply_unsubscription_policies(tenant)
    apply_comment_policy(tenant)
    apply_topic_policy(tenant)
  end

  def apply_comment_policy(tenant)
    return unless tenant.comment_policy_delete?

    comment_ids = user.comments_in_tenant(tenant).pluck(:id)
    Comment.delete_with_dependencies(comment_ids)
  end

  def apply_topic_policy(tenant)
    case tenant.unsubscribed_user_topic_policy
    when 'delete'
      topic_ids = user.topics_in_tenant(tenant).pluck(:id)
      Topic.delete_with_dependencies(topic_ids)
    when 'lock'
      user.topics_in_tenant(tenant).unlocked.update_all(locked_at: Time.current)
    when 'keep_visible'
      # 何もしない
    end
  end
end
