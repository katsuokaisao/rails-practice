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
class Report < ApplicationRecord
  belongs_to :reporter, class_name: 'User'
  belongs_to :reportable, polymorphic: true, optional: true
  has_one :decision, dependent: :restrict_with_error

  scope :similar_reports, lambda { |report|
    where(reportable: report.reportable).where.not(id: report.id)
  }

  validates :reportable_type, presence: true, inclusion: { in: %w[Comment User] }
  validates :reason_type, presence: true
  validates :reason_text, presence: true, length: { maximum: 2000 }, no_html: true
  validate :reportable_presence

  enum :reason_type,
       { spam: 'spam', harassment: 'harassment', obscene: 'obscene', other: 'other' },
       prefix: true, validate: true

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

  private

  def reportable_presence
    errors.add(:reportable, 'must be present') if reportable.nil?
  end
end
