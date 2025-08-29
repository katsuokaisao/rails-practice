# frozen_string_literal: true

FactoryBot.define do
  factory :decision do
    association :report
    association :moderator

    decision_type do
      case report.target_type
      when 'comment'
        %w[reject hide_comment].sample
      when 'user'
        %w[reject suspend_user].sample
      else
        'reject'
      end
    end
    note { Faker::Lorem.paragraph }

    after(:build) do |decision|
      if decision.decision_type == 'suspend_user'
        suspension_days = [7, 14, 30, 90].sample
        decision.suspension_until = Time.current + suspension_days.days
      end
    end

    trait :reject do
      decision_type { 'reject' }
    end

    trait :hide_comment do
      decision_type { 'hide_comment' }

      after(:build) do |decision|
        decision.report = build(:report, :for_comment) if decision.report.target_type != 'comment'
      end
    end

    trait :suspend_user do
      decision_type { 'suspend_user' }
      suspension_until { [7, 14, 30, 90].sample.days.from_now }

      after(:build) do |decision|
        decision.report = build(:report, :for_user) if decision.report.target_type != 'user'
      end
    end
  end
end
