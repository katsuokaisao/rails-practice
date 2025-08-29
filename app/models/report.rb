# frozen_string_literal: true

class Report < ApplicationRecord
  belongs_to :reporter, class_name: 'User'
  belongs_to :target_user, class_name: 'User', optional: true
  belongs_to :target_comment, class_name: 'Comment', optional: true
  has_one :decision, dependent: :restrict_with_error

  validates :target_type, presence: true, inclusion: { in: %w[comment user] }
  validates :reason_type, presence: true
  validates :reason_text, presence: true
  validate :target_presence
  validates :reason_text, length: { maximum: 2000 }

  enum :reason_type, { spam: 'spam', harassment: 'harassment', obscene: 'obscene', other: 'other' }, prefix: true,
                                                                                                     validates: true

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
    if target_type == 'user' && target_user.nil?
      errors.add(:target_user, 'must be present')
    elsif target_type == 'comment' && target_comment.nil?
      errors.add(:target_comment, 'must be present')
    end
  end
end
