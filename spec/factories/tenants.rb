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
FactoryBot.define do
  factory :tenant do
    sequence(:name) { |n| "テナント#{n}" }
    sequence(:identifier) { |n| "tenant-#{n}" }
    description { Faker::Lorem.sentence }
    unsubscribed_user_comment_policy { :hide_content }
    unsubscribed_user_topic_policy { :lock }

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
