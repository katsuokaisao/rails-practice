# frozen_string_literal: true

# == Schema Information
#
# Table name: tenant_memberships
#
#  id           :bigint           not null, primary key
#  display_name :string(255)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  tenant_id    :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  idx_tenant_memberships_tenant_display_name  (tenant_id,display_name) UNIQUE
#  idx_tenant_memberships_tenant_user          (tenant_id,user_id) UNIQUE
#  idx_tenant_memberships_user_id              (user_id)
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
end
