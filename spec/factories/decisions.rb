# frozen_string_literal: true

# == Schema Information
#
# Table name: decisions
#
#  id                                                                :bigint           not null, primary key
#  decided_by                                                        :bigint           not null
#  decision_type((enum: 'reject' | 'hide_comment' | 'suspend_user')) :string(255)      not null
#  note                                                              :text(65535)
#  suspended_until                                                   :datetime
#  created_at                                                        :datetime         not null
#  report_id                                                         :bigint           not null
#
# Indexes
#
#  idx_decisions_decided_by  (decided_by)
#  idx_decisions_report_id   (report_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (decided_by => moderators.id)
#  fk_rails_...  (report_id => reports.id)
#
FactoryBot.define do
  factory :decision do
    association :decider, factory: :moderator

    decision_type do
      case report.reportable_type
      when 'Comment'
        %w[reject hide_comment].sample
      when 'User'
        %w[reject suspend_user].sample
      else
        'reject'
      end
    end
    note { Faker::Lorem.paragraph }

    after(:build) do |decision|
      if decision.decision_type == 'suspend_user'
        suspension_days = [7, 14, 30, 90].sample
        decision.suspended_until = Time.current + suspension_days.days
      end
    end

    after(:build) do |decision|
      decision.report = build(:report, :for_comment) if decision.report.nil?
    end

    trait :reject do
      decision_type { 'reject' }
    end

    trait :hide_comment do
      decision_type { 'hide_comment' }

      after(:build) do |decision|
        decision.report = create(:report, :for_comment)
      end
    end

    trait :suspend_user do
      decision_type { 'suspend_user' }
      suspended_until { [7, 14, 30, 90].sample.days.from_now }

      after(:build) do |decision|
        decision.report = create(:report, :for_user)
      end
    end
  end
end
