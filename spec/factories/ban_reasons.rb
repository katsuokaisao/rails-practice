# frozen_string_literal: true

# == Schema Information
#
# Table name: ban_reasons
#
#  id                               :bigint           not null, primary key
#  active                           :boolean          default(TRUE), not null
#  description                      :text(65535)
#  name                             :string(255)      not null
#  system(システム基本理由かどうか) :boolean          default(FALSE), not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  tenant_id                        :bigint           not null
#
# Indexes
#
#  idx_ban_reasons_tenant_id_active  (tenant_id,active)
#  uniq_ban_reasons_tenant_name      (tenant_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (tenant_id => tenants.id)
#
FactoryBot.define do
  factory :ban_reason do
    tenant
    sequence(:name) { |n| "カスタム理由#{n}" }
    description { 'カスタムBAN理由の説明' }
    active { true }
    system { false }

    trait :system_reason do
      system { true }
      sequence(:name) { |n| "system_reason_#{n}" }
      description { nil }
    end

    trait :inactive do
      active { false }
    end

    trait :with_reports do
      after(:create) do |ban_reason|
        create(:report, :for_comment, tenant: ban_reason.tenant, ban_reason: ban_reason)
      end
    end
  end
end
