# frozen_string_literal: true

class BulkUnsubscriptionProcessor
  include ActiveModel::Validations

  attr_accessor :user, :tenant_ids

  validates :user, presence: true
  validates :tenant_ids, presence: true

  def initialize(user, tenant_ids)
    @user = user
    @tenant_ids = Array(tenant_ids).map(&:to_i)
  end

  def execute
    raise ActiveModel::ValidationError, self unless valid?

    ActiveRecord::Base.transaction do
      tenant_ids.each do |tenant_id|
        process_single_unsubscription(tenant_id)
      end
    end
  end

  private

  def process_single_unsubscription(tenant_id)
    tenant = Tenant.find(tenant_id)
    record_unsubscription_history(tenant)
    handle_user_content(tenant)
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

  def handle_user_content(tenant)
    apply_comment_policy(tenant)
    apply_topic_policy(tenant)
  end

  def apply_comment_policy(tenant)
    return unless tenant.comment_policy_delete?

    comment_ids = user.comments_in_tenant(tenant).pluck(:id)
    return if comment_ids.empty?

    Comment.delete_with_dependencies(comment_ids)
  end

  def apply_topic_policy(tenant)
    case tenant.unsubscribed_user_topic_policy
    when 'delete'
      topic_ids = user.topics_in_tenant(tenant).pluck(:id)
      return if topic_ids.empty?

      Topic.delete_with_dependencies(topic_ids)
    when 'lock'
      user.topics_in_tenant(tenant).unlocked.update_all(locked_at: Time.current)
    when 'keep_visible'
      # 何もしない
    end
  end
end
