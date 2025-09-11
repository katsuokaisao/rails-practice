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
class Report < ApplicationRecord
  belongs_to :reporter, class_name: 'User'
  belongs_to :target, polymorphic: true, optional: true
  has_one :decision, dependent: :restrict_with_error

  scope :same_target_as, ->(target_id, target_type) { where(target_type: target_type, target_id: target_id) }
  scope :without_report, ->(report) { where.not(id: report.id) }

  validates :target_type, presence: true, inclusion: { in: %w[Comment User] }
  validates :reason_type, presence: true
  validates :reason_text, presence: true, length: { maximum: 2000 }, no_html: true
  validate :target_presence

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

  def target_presence
    errors.add(:target, 'must be present') if target.nil?
  end
end
