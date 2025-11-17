# frozen_string_literal: true

# == Schema Information
#
# Table name: tenant_memberships
#
#  id              :bigint           not null, primary key
#  display_name    :string(255)      not null
#  suspended_until :datetime
#  unsubscribed_at :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  tenant_id       :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  idx_tenant_memberships_tenant_display_name     (tenant_id,display_name) UNIQUE
#  idx_tenant_memberships_tenant_unsubscribed_at  (tenant_id,unsubscribed_at)
#  idx_tenant_memberships_tenant_user             (tenant_id,user_id) UNIQUE
#  idx_tenant_memberships_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (tenant_id => tenants.id)
#  fk_rails_...  (user_id => users.id)
#
class TenantMembership < ApplicationRecord
  belongs_to :tenant
  belongs_to :user

  validates :display_name, presence: true,
                           length: { maximum: 50 }
  validates :display_name, uniqueness: { scope: :tenant_id,
                                         case_sensitive: true }
  validates :user_id, uniqueness: { scope: :tenant_id }

  validate :suspended_until_future

  scope :active, -> { where(unsubscribed_at: nil) }
  scope :unsubscribed, -> { where.not(unsubscribed_at: nil) }

  def suspended?
    suspended_until.present? && suspended_until.future?
  end

  def suspend!(suspended_until)
    update!(suspended_until: suspended_until)
  end

  def suspended_until_date
    return unless suspended?

    suspended_until.to_date
  end

  def enforce_release_suspension!
    return unless suspended?

    update!(suspended_until: nil)
  end

  def unsubscribed?
    unsubscribed_at.present?
  end

  def active?
    unsubscribed_at.nil?
  end

  private

  def suspended_until_future
    return if suspended_until.nil?

    errors.add(:suspended_until, :must_be_in_future) unless suspended_until.future?
  end
end
