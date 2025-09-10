# frozen_string_literal: true

# == Schema Information
#
# Table name: decisions
#
#  id                                                                :bigint           not null, primary key
#  decided_by                                                        :bigint           not null
#  decision_type((enum: 'reject' | 'hide_comment' | 'suspend_user')) :string(255)      not null
#  note                                                              :text(65535)
#  suspension_until                                                  :datetime
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
  validates :decision_type, presence: true
  validates :note, length: { maximum: 2000 }, allow_blank: true
  validate :target_type_must_be_comment_report, if: :decision_type_hide_comment?
  validate :target_type_must_be_user_report, if: :decision_type_suspend_user?
  validate :suspension_until_presence, if: :decision_type_suspend_user?
  validate :suspension_until_absence, unless: :decision_type_suspend_user?
  validate :suspension_until_future, if: -> { suspension_until.present? && decision_type_suspend_user? }

  def execute!
    ActiveRecord::Base.transaction do
      save!
      apply_effect!
    end
    propagate_to_similar_reports!
  end

  def report_type
    report.target_type
  end

  private

  def apply_effect!
    case decision_type
    when 'hide_comment'
      hide_comment!
    when 'suspend_user'
      suspend_user!
    end
  end

  def hide_comment!
    report.target_comment.hide_by_decision!(self)
  end

  def suspend_user!
    report.target_user.suspend!(suspension_until)
  end

  def propagate_to_similar_reports!
    similar_reports = case report_type
                      when 'comment'
                        similar_content_reports
                      when 'user'
                        similar_user_reports
                      end

    similar_reports.each do |similar_report|
      next if similar_report.reviewed?

      Decision.create!(
        report: similar_report,
        decision_type: decision_type,
        note: auto_note,
        decider: decider,
        suspension_until: decision_type_suspend_user? ? suspension_until : nil
      )
    end
  end

  def similar_content_reports
    Report.same_comment_as(report.target_comment_id).without_report(report)
  end

  def similar_user_reports
    Report.same_user_as(report.target_user_id).without_report(report)
  end

  def auto_note
    "自動作成: 関連する通報 ##{report.id} の審査結果に基づく"
  end

  def target_type_must_be_comment_report
    errors.add(:report, :invalid_for_comment_report) if report && report.target_type != 'comment'
  end

  def target_type_must_be_user_report
    errors.add(:report, :invalid_for_user_report) if report && report.target_type != 'user'
  end

  def suspension_until_presence
    errors.add(:suspension_until, :required_for_suspension) if suspension_until.blank?
  end

  def suspension_until_absence
    errors.add(:suspension_until, :not_allowed_for_non_suspension) if suspension_until.present?
  end

  def suspension_until_future
    errors.add(:suspension_until, :must_be_in_future) unless suspension_until.future?
  end
end
