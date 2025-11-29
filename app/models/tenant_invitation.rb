# frozen_string_literal: true

# == Schema Information
#
# Table name: tenant_invitations
#
#  id                                                               :bigint           not null, primary key
#  status((enum: 'pending' | 'accepted' | 'rejected' | 'canceled')) :string(255)      default("pending"), not null
#  created_at                                                       :datetime         not null
#  updated_at                                                       :datetime         not null
#  invited_user_id                                                  :bigint           not null
#  inviter_id                                                       :bigint           not null
#  tenant_id                                                        :bigint           not null
#
# Indexes
#
#  idx_tenant_invitations_invited_user_status  (invited_user_id,status)
#  idx_tenant_invitations_inviter              (inviter_id)
#  idx_tenant_invitations_tenant_user_pending  (tenant_id,invited_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (invited_user_id => users.id)
#  fk_rails_...  (inviter_id => users.id)
#  fk_rails_...  (tenant_id => tenants.id)
#
class TenantInvitation < ApplicationRecord
  enum :status,
       { pending: 'pending', accepted: 'accepted', rejected: 'rejected', canceled: 'canceled' },
       prefix: true, validate: true, default: :pending

  belongs_to :tenant
  belongs_to :inviter, class_name: 'User'
  belongs_to :invited_user, class_name: 'User', optional: true

  counter_culture :invited_user,
                  column_name: proc { |model| model.status_pending? ? 'pending_invitations_count' : nil }

  validates :invited_user_id, uniqueness: {
    scope: :tenant_id,
    conditions: -> { status_pending }
  }
  validate :validate_invited_user

  def accept(display_name:)
    tenant_membership = invited_user.tenant_memberships.build(
      tenant: tenant,
      display_name: display_name
    )

    transaction do
      tenant_membership.save!
      status_accepted!
    end

    [true, tenant_membership]
  rescue ActiveRecord::RecordInvalid
    [false, tenant_membership]
  end

  def reject
    status_rejected!
  end

  def already_member?
    tenant.tenant_memberships.exists?(user_id: invited_user_id)
  end

  private

  def validate_invited_user
    return errors.add(:invited_user_id, :required) if invited_user_id.blank?
    return errors.add(:invited_user_id, :not_exist) unless User.exists?(id: invited_user_id)
    return errors.add(:invited_user_id, :invalid_self) if self_invitation?
    return errors.add(:invited_user_id, :unsubscribed) if unsubscribed_user?
    return unless status_pending?

    errors.add(:invited_user_id, :already_member) if already_member?
  end

  def unsubscribed_user?
    return false if invited_user_id.blank? || tenant_id.blank?

    TenantUnsubscriptionHistory.exists?(user_id: invited_user_id, tenant_id: tenant_id)
  end

  def self_invitation?
    inviter == invited_user
  end
end
