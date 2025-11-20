# frozen_string_literal: true

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
