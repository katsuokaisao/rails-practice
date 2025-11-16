# frozen_string_literal: true

# == Schema Information
#
# Table name: tenants
#
#  id                               :bigint           not null, primary key
#  description                      :text(65535)      not null
#  identifier                       :string(255)      not null
#  name                             :string(255)      not null
#  unsubscribed_user_comment_policy :string(255)      not null
#  unsubscribed_user_topic_policy   :string(255)      not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#
# Indexes
#
#  idx_tenants_identifier  (identifier) UNIQUE
#  idx_tenants_name        (name)
#
class Tenant < ApplicationRecord
  has_many :tenant_memberships, dependent: :destroy
  has_many :members, through: :tenant_memberships, source: :user
  has_many :tenant_invitations, dependent: :destroy

  has_many :topics, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :decisions, dependent: :destroy
  has_many :moderators, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }

  enum :unsubscribed_user_topic_policy, {
    keep_visible: 'keep_visible',
    lock: 'lock',
    delete: 'delete'
  }, prefix: :topic, validate: true

  enum :unsubscribed_user_comment_policy, {
    keep_visible: 'keep_visible',
    hide_content: 'hide_content',
    delete: 'delete'
  }, prefix: :comment, validate: true

  validates :identifier,
            presence: true,
            uniqueness: true,
            length: { maximum: 50 },
            format: {
              with: /\A[a-z0-9-]+\z/
            }

  validates :description, presence: true, length: { maximum: 500 }

  after_update :apply_topic_policy,
               if: :saved_change_to_unsubscribed_user_topic_policy?

  after_update :apply_comment_policy,
               if: :saved_change_to_unsubscribed_user_comment_policy?

  def member?(user)
    return false if user.nil?

    tenant_memberships.exists?(user: user)
  end

  def apply_topic_policy
    topic_ids = unsubscribed_users_topic_ids
    return if topic_ids.empty?

    apply_topic_policy_action(topic_ids)
  end

  def apply_comment_policy
    return unless comment_delete?

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
    ActiveRecord::Base.transaction do
      case unsubscribed_user_topic_policy
      when 'keep_visible'
        Topic.where(id: topic_ids).locked.update_all(locked_at: nil)
      when 'lock'
        Topic.where(id: topic_ids).unlocked.update_all(locked_at: Time.current)
      when 'delete'
        topic_ids.each_slice(1000) { |batch_ids| Topic.delete_with_dependencies(batch_ids) }
      end
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
