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
class Decision < ApplicationRecord
  belongs_to :report
  belongs_to :decider, class_name: 'Moderator', foreign_key: 'decided_by', inverse_of: :decisions
  enum :decision_type, { reject: 'reject', hide_comment: 'hide_comment', suspend_user: 'suspend_user' },
       prefix: true, validate: true

  validates :report_id, uniqueness: true
  validates :note, length: { maximum: 2000 }, allow_blank: true

  validate :suspended_until_must_match_decision_type
  validate :reportable_type_must_be_comment_report, if: :decision_type_hide_comment?
  validate :reportable_type_must_be_user_report, if: :decision_type_suspend_user?
  validate :suspended_until_future, if: -> { suspended_until.present? && decision_type_suspend_user? }

  def execute!
    ActiveRecord::Base.transaction do
      save!
      apply_decision! unless decision_type_reject?
    end
    apply_decision_for_similar_reports! unless decision_type_reject?
  end

  def report_type
    report.reportable_type
  end

  def similar_reports
    Report.similar_reports(report)
  end

  private

  def apply_decision!
    report.reportable.apply_decision!(self)
  end

  def apply_decision_for_similar_reports!
    similar_reports.each do |similar_report|
      next if similar_report.reviewed?

      Decision.create!(
        report: similar_report,
        decision_type: decision_type,
        note: auto_note,
        decider: decider,
        suspended_until: decision_type_suspend_user? ? suspended_until : nil
      )
    end
  end

  def auto_note
    "自動作成: 関連する通報 ##{report.id} の審査結果に基づく"
  end

  def reportable_type_must_be_comment_report
    errors.add(:report, :invalid_for_comment_report) if report && report.reportable_type != 'Comment'
  end

  def reportable_type_must_be_user_report
    errors.add(:report, :invalid_for_user_report) if report && report.reportable_type != 'User'
  end

  def suspended_until_future
    errors.add(:suspended_until, :must_be_in_future) unless suspended_until.future?
  end

  def suspended_until_must_match_decision_type
    if decision_type_suspend_user?
      errors.add(:suspended_until, :blank) if suspended_until.blank?
    elsif decision_type_hide_comment?
      errors.add(:suspended_until, :present) if suspended_until.present?
    end
  end
end
