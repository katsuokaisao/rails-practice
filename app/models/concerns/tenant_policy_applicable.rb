# frozen_string_literal: true

module TenantPolicyApplicable
  extend ActiveSupport::Concern

  def apply_topic_policy
    topic_ids = unsubscribed_users_topic_ids
    return if topic_ids.empty?

    apply_topic_policy_action(topic_ids)
  end

  def apply_comment_policy
    return unless comment_policy_delete?

    comment_ids = unsubscribed_users_comment_ids
    return if comment_ids.empty?

    delete_comments_in_batches(comment_ids)
  end

  private

  def unsubscribed_users_topic_ids
    Topic
      .joins('INNER JOIN tenant_memberships ON tenant_memberships.user_id = topics.author_id')
      .where(
        topics: { tenant_id: id },
        tenant_memberships: { tenant_id: id }
      )
      .where.not(tenant_memberships: { unsubscribed_at: nil })
      .pluck('topics.id')
      .uniq
  end

  def apply_topic_policy_action(topic_ids)
    case unsubscribed_user_topic_policy
    when 'keep_visible'
      Topic.where(id: topic_ids).locked.update_all(locked_at: nil)
    when 'lock'
      Topic.where(id: topic_ids).unlocked.update_all(locked_at: Time.current)
    when 'delete'
      topic_ids.each_slice(1000) { |batch_ids| Topic.delete_with_dependencies(batch_ids) }
    end
  end

  def unsubscribed_users_comment_ids
    Comment
      .joins(:topic)
      .joins('INNER JOIN tenant_memberships ON tenant_memberships.user_id = comments.author_id')
      .where(
        topics: { tenant_id: id },
        tenant_memberships: { tenant_id: id }
      )
      .where.not(tenant_memberships: { unsubscribed_at: nil })
      .pluck('comments.id')
      .uniq
  end

  def delete_comments_in_batches(comment_ids)
    ActiveRecord::Base.transaction do
      comment_ids.each_slice(1000) { |batch_ids| Comment.delete_with_dependencies(batch_ids) }
    end
  end
end
