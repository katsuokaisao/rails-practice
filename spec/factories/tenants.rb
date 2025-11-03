# frozen_string_literal: true

# == Schema Information
#
# Table name: tenants
#
#  id                          :bigint           not null, primary key
#  description(テナントの説明) :text(65535)      not null
#  identifier(テナント識別子)  :string(255)      not null
#  name(テナント名（表示用）)  :string(255)      not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  idx_tenants_identifier  (identifier) UNIQUE
#  idx_tenants_name        (name)
#
FactoryBot.define do
  factory :tenant do
    sequence(:name) { |n| "テナント#{n}" }
    sequence(:identifier) { |n| "tenant-#{n}" }
    description { Faker::Lorem.sentence }

    trait :with_members do
      transient do
        member_count { 5 }
        members { [] }
      end

      after(:create) do |tenant, evaluator|
        users_to_add = if evaluator.members.any?
                         evaluator.members
                       else
                         create_list(:user, evaluator.member_count)
                       end

        users_to_add.each_with_index do |user, index|
          create(:tenant_membership,
                 tenant: tenant,
                 user: user,
                 display_name: "メンバー#{index + 1}")
        end
      end
    end
  end
end
