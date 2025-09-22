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
#  idx_decisions_created_at_report_id  (created_at,report_id)
#  idx_decisions_decided_by            (decided_by)
#  idx_decisions_report_id             (report_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (decided_by => moderators.id)
#  fk_rails_...  (report_id => reports.id)
#
class Decision < ApplicationRecord
  MAX_BULK_INSERT_SIZE = 10_000

  belongs_to :report
  belongs_to :decider, class_name: 'Moderator', foreign_key: 'decided_by', inverse_of: :decisions

  enum :decision_type, { reject: 'reject', hide_comment: 'hide_comment', suspend_user: 'suspend_user' },
       prefix: true, validate: true
  validates :decision_type, presence: true
  validates :report_id, uniqueness: true
  validates :note, length: { maximum: 2000 }, allow_blank: true

  validate :reportable_type_must_match_decision_type
  validate :suspended_until_must_match_decision_type

  after_create :apply_decision!, unless: :decision_type_reject?
  after_commit :apply_decision_for_similar_reports!, on: :create, unless: :decision_type_reject?

  def report_type
    report.reportable_type
  end

  def similar_reports
    Report.similar_reports(report)
  end

  def similar_unreviewed_reports
    similar_reports.where.missing(:decision).includes(:decision).limit(MAX_BULK_INSERT_SIZE)
  end

  private

  def apply_decision!
    report.reportable.apply_decision!(self)
  end

  def apply_decision_for_similar_reports!
    report_ids = similar_unreviewed_reports.pluck(:id)
    return if report_ids.empty?

    # ON DUPLICATE KEY UPDATE `report_id`=`decisions`.`report_id` が付与されるので衝突した時に値も更新されずエラーも発生しない
    Decision.insert_all(build_similar_decisions_from_report_ids(report_ids))
  end

  def build_similar_decisions_from_report_ids(report_ids)
    now = Time.current
    report_ids.map do |rid|
      {
        report_id: rid,
        decision_type: decision_type,
        note: auto_note,
        decided_by: decided_by,
        suspended_until: suspended_until,
        created_at: now
      }
    end
  end

  def auto_note
    "自動作成: 関連する通報 ##{report.id} の審査結果に基づく"
  end

  def reportable_type_must_match_decision_type
    if decision_type_hide_comment? && !report.reportable_type_comment?
      errors.add(:report, :invalid_for_comment_report)
    elsif decision_type_suspend_user? && !report.reportable_type_user?
      errors.add(:report, :invalid_for_user_report)
    end
  end

  def suspended_until_must_match_decision_type
    if decision_type_suspend_user?
      if suspended_until.blank?
        errors.add(:suspended_until, :blank)
      elsif !suspended_until.future?
        errors.add(:suspended_until, :must_be_in_future)
      end
    elsif suspended_until.present?
      errors.add(:suspended_until, :present)
    end
  end
end
