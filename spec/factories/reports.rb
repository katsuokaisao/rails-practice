# frozen_string_literal: true

# == Schema Information
#
# Table name: reports
#
#  id                                      :bigint           not null, primary key
#  reason_text                             :text(65535)      not null
#  reason_type                             :string(255)      not null
#  target_type((enum: 'Comment' | 'User')) :string(255)      not null
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  reporter_id                             :bigint           not null
#  target_id                               :bigint
#
# Indexes
#
#  idx_reports_reporter_id             (reporter_id)
#  idx_reports_target                  (target_type,target_id)
#  idx_reports_target_type_created_at  (target_type,created_at)
#
FactoryBot.define do
  factory :report do
    association :reporter, factory: :user
    reason_type { %w[spam harassment obscene other].sample }
    reason_text { Faker::Lorem.paragraph }

    trait :for_user do
      target_type { 'User' }
      association :target, factory: :user

      # reporter と target_user の衝突回避
      after(:build) do |report|
        report.target = build(:user) if report.target == report.reporter
      end
    end

    trait :for_comment do
      target_type { 'Comment' }
      association :target, factory: :comment

      after(:build) do |report|
        author = report.target&.author
        report.reporter = build(:user) if author == report.reporter
      end
    end
  end
end
