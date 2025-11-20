# frozen_string_literal: true

# == Schema Information
#
# Table name: reports
#
#  id                                          :bigint           not null, primary key
#  reason_text                                 :text(65535)      not null
#  reportable_type((enum: 'Comment' | 'User')) :string(255)      not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  ban_reason_id                               :bigint           not null
#  reportable_id                               :bigint
#  reporter_id                                 :bigint           not null
#  tenant_id                                   :bigint           not null
#
# Indexes
#
#  idx_reports_ban_reason_id                  (ban_reason_id)
#  idx_reports_reportable_type_created_at     (tenant_id,reportable_type,created_at)
#  idx_reports_reportable_type_reportable_id  (tenant_id,reportable_type,reportable_id)
#  idx_reports_reporter_id                    (tenant_id,reporter_id)
#
# Foreign Keys
#
#  fk_rails_...  (ban_reason_id => ban_reasons.id)
#  fk_rails_...  (tenant_id => tenants.id)
#
FactoryBot.define do
  factory :report do
    association :tenant
    association :reporter, factory: :user
    association :ban_reason
    reason_text { Faker::Lorem.paragraph }

    after(:build) do |report|
      report.ban_reason.tenant = report.tenant if report.ban_reason
    end

    trait :for_user do
      association :reportable, factory: :user

      # reporter と reportable_user の衝突回避
      after(:build) do |report|
        report.reportable = build(:user) if report.reportable == report.reporter
      end

      after(:create) do |report|
        unless report.reportable.member_of?(report.tenant)
          create(:tenant_membership, tenant: report.tenant, user: report.reportable,
                                     display_name: "reportable_#{report.reportable.id}_#{report.tenant.id}")
        end
        unless report.reporter.member_of?(report.tenant)
          create(:tenant_membership, tenant: report.tenant, user: report.reporter,
                                     display_name: "reporter_#{report.reporter.id}_#{report.tenant.id}")
        end
      end
    end

    trait :for_comment do
      association :reportable, factory: :comment

      after(:build) do |report|
        author = report.reportable&.author
        report.reporter = build(:user) if author == report.reporter
      end

      after(:create) do |report|
        unless report.reporter.member_of?(report.tenant)
          create(:tenant_membership, tenant: report.tenant, user: report.reporter,
                                     display_name: "reporter_#{report.reporter.id}_#{report.tenant.id}")
        end
      end
    end
  end
end
