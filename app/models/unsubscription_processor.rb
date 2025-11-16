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
      create_unsubscription_history
      process_author_content
      update_membership
    end
  end

  private

  def create_unsubscription_history
    TenantUnsubscriptionHistory.create!(
      user_id: user.id,
      tenant_id: tenant.id,
      comment_policy: tenant.unsubscribed_user_comment_policy,
      topic_policy: tenant.unsubscribed_user_topic_policy,
      unsubscribed_at: Time.current
    )
  end

  def process_author_content
    process_comments
    process_topics
  end

  def process_comments
    return unless tenant.comment_delete?

    comment_ids = user.comments_in_tenant(tenant).pluck(:id)
    return if comment_ids.empty?

    Comment.delete_with_dependencies(comment_ids)
  end

  def process_topics
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

  def update_membership
    membership.update!(unsubscribed_at: Time.current) if membership.unsubscribed_at.nil?
  end
end
