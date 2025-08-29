# frozen_string_literal: true

class Decision < ApplicationRecord
  belongs_to :report
  belongs_to :moderator, class_name: 'Moderator', foreign_key: 'decided_by', inverse_of: :decisions
  enum :decision_type, { reject: 'reject', hide_comment: 'hide_comment', suspend_user: 'suspend_user' },
       prefix: true, validates: true

  validates :report_id, uniqueness: true
  validates :decision_type, presence: true
  validate :validate_decision_type_with_report_type
  validate :validate_suspension_until

  private

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
end
