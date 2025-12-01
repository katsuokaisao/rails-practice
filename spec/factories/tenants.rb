# frozen_string_literal: true

# == Schema Information
#
# Table name: tenants
#
#  id                                                                                                           :bigint           not null, primary key
#  applying_policy(ポリシー適用状態（idle / progress / failed）)                                                :string(255)      default("idle"), not null
#  description(テナントの説明)                                                                                  :text(65535)      not null
#  name(テナント名（表示用）)                                                                                   :string(255)      not null
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
FactoryBot.define do
  factory :tenant do
    sequence(:name) { |n| "テナント#{n}" }
    sequence(:slug) { |n| "tenant-#{n}" }
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
