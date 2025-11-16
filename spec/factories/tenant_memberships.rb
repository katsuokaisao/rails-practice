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
FactoryBot.define do
  factory :tenant_membership do
    association :tenant
    association :user
    sequence(:display_name) { |n| "ユーザー#{n}" }
    unsubscribed_at { nil }

    trait :suspended do
      suspended_until { 1.day.from_now }
    end

    trait :unsubscribed do
      unsubscribed_at { 1.day.ago }
    end
  end
end
