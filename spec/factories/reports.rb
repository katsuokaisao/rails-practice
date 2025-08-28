# frozen_string_literal: true

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
