# frozen_string_literal: true

# == Schema Information
#
# Table name: topics
#
#  id            :bigint           not null, primary key
#  locked_at     :datetime
#  title         :string(255)      not null
#  total_comment :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  author_id     :bigint           not null
#  tenant_id     :bigint           not null
#
# Indexes
#
#  idx_topics_author_id             (author_id)
#  idx_topics_tenant_id_created_at  (tenant_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (tenant_id => tenants.id)
#
FactoryBot.define do
  factory :topic do
    association :tenant
    association :author, factory: :user
    sequence(:title) { |n| "タイトル#{n}" }
    locked_at { nil }

    trait :locked do
      locked_at { 1.day.ago }
    end
  end
end
