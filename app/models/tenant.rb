# frozen_string_literal: true

# == Schema Information
#
# Table name: tenants
#
#  id                                                                                                           :bigint           not null, primary key
#  description(テナントの説明)                                                                                  :text(65535)      not null
#  name(テナント名（表示用）)                                                                                   :string(255)      not null
#  policy_application_status(ポリシー適用状態（idle / applying / failed）)                                      :string(255)      default("idle"), not null
#  slug(テナント識別子)                                                                                         :string(255)      not null
#  unsubscribed_user_comment_policy(退会ユーザーのコメント表示ポリシー（keep_visible / hide_content / delete）) :string(255)      default("keep_visible"), not null
#  unsubscribed_user_topic_policy(退会ユーザーのトピック表示ポリシー（keep_visible / lock / delete）)           :string(255)      default("keep_visible"), not null
#  created_at                                                                                                   :datetime         not null
#  updated_at                                                                                                   :datetime         not null
#
# Indexes
#
#  idx_tenants_slug  (slug) UNIQUE
#
class Tenant < ApplicationRecord
  include TenantPolicyApplicable

  has_many :tenant_memberships, dependent: :destroy
  has_many :members, through: :tenant_memberships, source: :user
  has_many :tenant_invitations, dependent: :destroy

  has_many :topics, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :decisions, dependent: :destroy
  has_many :moderators, dependent: :destroy
  has_many :ban_reasons, dependent: :destroy

  after_create :create_default_ban_reasons

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

  enum :policy_application_status, {
    idle: 'idle',
    applying: 'applying',
    failed: 'failed'
  }, prefix: :status, validate: true

  validates :slug,
            presence: true,
            uniqueness: true,
            length: { maximum: 50 },
            format: {
              with: /\A[a-z0-9-]+\z/
            }

  validates :description, presence: true, length: { maximum: 500 }

  validate :cannot_update_policy_while_applying, on: :update

  after_update :apply_policy_later, if: :policy_changed?

  def member?(user)
    return false if user.nil?

    tenant_memberships.exists?(user: user)
  end

  private

  def cannot_update_policy_while_applying
    return unless status_applying?

    errors.add(:unsubscribed_user_topic_policy, :policy_applying) if unsubscribed_user_topic_policy_changed?

    return unless unsubscribed_user_comment_policy_changed?

    errors.add(:unsubscribed_user_comment_policy, :policy_applying)
  end

  def apply_policy_later
    changed_policies = []
    changed_policies << :topic if saved_change_to_unsubscribed_user_topic_policy?
    changed_policies << :comment if saved_change_to_unsubscribed_user_comment_policy?

    status_applying!
    ApplyPolicyJob.perform_later(id, changed_policies)
  end

  def policy_changed?
    saved_change_to_unsubscribed_user_topic_policy? ||
      saved_change_to_unsubscribed_user_comment_policy?
  end

  def create_default_ban_reasons
    default_reasons = [
      { name: 'spam', system: true },
      { name: 'harassment', system: true },
      { name: 'obscene', system: true },
      { name: 'other', system: true }
    ]

    default_reasons.each do |reason_attrs|
      ban_reasons.create!(reason_attrs)
    end
  end
end
