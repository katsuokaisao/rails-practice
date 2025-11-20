# frozen_string_literal: true

# == Schema Information
#
# Table name: reports
#
#  id              :bigint           not null, primary key
#  reason_text     :text(65535)      not null
#  reportable_type :string(255)      not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  ban_reason_id   :bigint           not null
#  reportable_id   :bigint
#  reporter_id     :bigint           not null
#  tenant_id       :bigint           not null
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
class Report < ApplicationRecord
  REPORTABLE_CLASSES = [Comment, User].freeze

  POLYMORPHIC_FLAG_ASSOC_NAME = :reportable
  POLYMORPHIC_FLAG_CLASSES = REPORTABLE_CLASSES
  include PolymorphicTypeCheck

  belongs_to :tenant
  belongs_to :reporter, class_name: 'User'
  belongs_to :reportable, polymorphic: true
  belongs_to :ban_reason
  has_one :decision, dependent: :restrict_with_error

  scope :similar_reports, lambda { |report|
    where(tenant_id: report.tenant_id)
    .where(reportable: report.reportable)
    .where.not(id: report.id)
  }

  validates :reason_text, presence: true, length: { maximum: 2000 }, no_html: true

  def reviewed?
    decision.present?
  end

  def rejected?
    decision.decision_type_reject?
  end

  def comment_hidden?
    decision.decision_type_hide_comment?
  end

  def user_suspended?
    decision.decision_type_suspend_user?
  end

  def reason_type
    ban_reason.display_name
  end
end
