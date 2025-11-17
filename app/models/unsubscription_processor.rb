# frozen_string_literal: true

class UnsubscriptionProcessor
  include ActiveModel::Model

  attr_accessor :user, :tenant, :membership

  validates :user, presence: true
  validates :tenant, presence: true
  validates :membership, presence: true

  def initialize(membership)
    @membership = membership
    @user = membership&.user
    @tenant = membership&.tenant
  end

  def execute
    raise ActiveModel::ValidationError, self unless valid?

    ActiveRecord::Base.transaction do
      record_unsubscription_history
      handle_user_content
    end
  end

  private

  def record_unsubscription_history
    TenantUnsubscriptionHistory.create!(
      user_id: user.id,
      tenant_id: tenant.id,
      comment_policy: tenant.unsubscribed_user_comment_policy,
      topic_policy: tenant.unsubscribed_user_topic_policy,
      unsubscribed_at: Time.current
    )
  end

  def handle_user_content
    apply_comment_policy
    apply_topic_policy
  end

  def apply_comment_policy
    return unless tenant.comment_delete?

    comment_ids = user.comments_in_tenant(tenant).pluck(:id)
    return if comment_ids.empty?

    Comment.delete_with_dependencies(comment_ids)
  end

  def apply_topic_policy
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
