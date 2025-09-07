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
  belongs_to :moderator, class_name: 'Moderator', foreign_key: 'decided_by', inverse_of: :decisions
  enum :decision_type, { reject: 'reject', hide_comment: 'hide_comment', suspend_user: 'suspend_user' },
       prefix: true, validates: true

  validates :report_id, uniqueness: true
  validates :decision_type, presence: true
  validate :validate_decision_type_with_report_type
  validate :validate_suspension_until
  validates :note, length: { maximum: 2000 }, allow_blank: true
  validate :suspension_until_must_be_in_future

  def execute!
    ActiveRecord::Base.transaction do
      save!
      apply_effect!
    end
    propagate_to_similar_reports!
  end

  private

  def apply_effect!
    case decision_type
    when 'hide_comment'
      report.target_comment.hide_by_decision!(self)
    when 'suspend_user'
      report.target_user.suspend!(suspension_until)
    end
  end

  def propagate_to_similar_reports!
    case decision_type
    when 'hide_comment'
      propagate_to_similar_content_reports!
    when 'suspend_user'
      propagate_to_similar_user_reports!
    end
  end

  def propagate_to_similar_content_reports!
    similar_reports = Report.same_comment_as(report.target_comment_id).without_report(report)

    similar_reports.each do |similar_report|
      next if similar_report.reviewed?

      Decision.create!(
        report: similar_report,
        decision_type: 'hide_comment',
        note: "自動作成: 関連する通報 ##{report.id} の審査結果に基づく",
        moderator: moderator
      )
    end
  end

  def propagate_to_similar_user_reports!
    similar_reports = Report.same_user_as(report.target_user_id).without_report(report)

    similar_reports.each do |similar_report|
      next if similar_report.reviewed?

      Decision.create!(
        report: similar_report,
        decision_type: 'suspend_user',
        note: "自動作成: 関連する通報 ##{report.id} の審査結果に基づく",
        suspension_until: suspension_until,
        moderator: moderator
      )
    end
  end

  def validate_decision_type_with_report_type
    return unless report

    case report.target_type
    when 'comment'
      errors.add(:decision_type, :invalid_for_comment_report) if decision_type == 'suspend_user'
    when 'user'
      errors.add(:decision_type, :invalid_for_user_report) if decision_type == 'hide_comment'
    end
  end

  def validate_suspension_until
    if decision_type == 'suspend_user' && suspension_until.blank?
      errors.add(:suspension_until, :required_for_suspension)
    elsif decision_type != 'suspend_user' && suspension_until.present?
      errors.add(:suspension_until, :not_allowed_for_non_suspension)
    end
  end

  def suspension_until_must_be_in_future
    return if suspension_until.blank? || suspension_until.future?

    errors.add(:suspension_until, :must_be_in_future)
  end
end
