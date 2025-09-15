# frozen_string_literal: true

# == Schema Information
#
# Table name: reports
#
#  id                                          :bigint           not null, primary key
#  reason_text                                 :text(65535)      not null
#  reason_type                                 :string(255)      not null
#  reportable_type((enum: 'Comment' | 'User')) :string(255)      not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  reportable_id                               :bigint
#  reporter_id                                 :bigint           not null
#
# Indexes
#
#  idx_reports_reportable_type_created_at     (reportable_type,created_at)
#  idx_reports_reportable_type_reportable_id  (reportable_type,reportable_id)
#  idx_reports_reporter_id                    (reporter_id)
#
FactoryBot.define do
  factory :report do
    association :reporter, factory: :user
    reason_type { %w[spam harassment obscene other].sample }
    reason_text { Faker::Lorem.paragraph }

    trait :for_user do
      association :reportable, factory: :user

      # reporter と reportable_user の衝突回避
      after(:build) do |report|
        report.reportable = build(:user) if report.reportable == report.reporter
      end
    end

    trait :for_comment do
      association :reportable, factory: :comment

      after(:build) do |report|
        author = report.reportable&.author
        report.reporter = build(:user) if author == report.reporter
      end
    end
  end
end
