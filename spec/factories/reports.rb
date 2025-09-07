# frozen_string_literal: true

# == Schema Information
#
# Table name: reports
#
#  id                                      :bigint           not null, primary key
#  reason_text                             :text(65535)      not null
#  reason_type                             :string(255)      not null
#  target_type((enum: 'comment' | 'user')) :string(255)      not null
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  reporter_id                             :bigint           not null
#  target_comment_id                       :bigint
#  target_user_id                          :bigint
#
# Indexes
#
#  idx_reports_reporter_id             (reporter_id)
#  idx_reports_target_comment_id       (target_comment_id)
#  idx_reports_target_type_created_at  (target_type,created_at)
#  idx_reports_target_user_id          (target_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (reporter_id => users.id)
#  fk_rails_...  (target_comment_id => comments.id)
#  fk_rails_...  (target_user_id => users.id)
#
FactoryBot.define do
  factory :report do
    association :reporter, factory: :user
    reason_type { %w[spam harassment obscene other].sample }
    reason_text { Faker::Lorem.paragraph }

    after(:build) do |report|
      case report.target_type
      when 'user'
        report.target_comment = nil
      when 'comment'
        report.target_user = nil
      end
    end

    trait :for_user do
      target_type { 'user' }
      association :target_user, factory: :user

      # reporter と target_user の衝突回避
      after(:build) do |report|
        report.target_user = build(:user) if report.target_user == report.reporter
      end
    end

    trait :for_comment do
      target_type { 'comment' }
      association :target_comment, factory: :comment

      after(:build) do |report|
        author = report.target_comment&.author
        report.reporter = build(:user) if author == report.reporter
      end
    end
  end
end
