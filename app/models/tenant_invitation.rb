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
  belongs_to :invited_user, class_name: 'User'

  validates :invited_user_id, uniqueness: {
    scope: :tenant_id,
    conditions: -> { status_pending }
  }
  validate :validate_invited_user

  scope :recent, -> { order(created_at: :desc) }

  private

  def validate_invited_user
    if inviter == invited_user
      errors.add(:invited_user_id, :invalid_self)
    elsif tenant.tenant_memberships.exists?(user_id: invited_user_id)
      errors.add(:invited_user_id, :already_member)
    end
  end
end
