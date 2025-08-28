# frozen_string_literal: true

class Report < ApplicationRecord
  belongs_to :reporter, class_name: 'User'
  belongs_to :target_user, class_name: 'User', optional: true
  belongs_to :target_comment, class_name: 'Comment', optional: true

  validates :target_type, presence: true, inclusion: { in: %w[comment user] }
  validates :reason_type, presence: true
  validates :reason_text, presence: true
  validate :target_presence
  validates :reason_text, length: { maximum: 2000 }

  enum :reason_type, { spam: 'spam', harassment: 'harassment', obscene: 'obscene', other: 'other' }, prefix: true,
                                                                                                     validates: true

  private

  def target_presence
    if target_type == 'user' && target_user.nil?
      errors.add(:target_user, 'must be present')
    elsif target_type == 'comment' && target_comment.nil?
      errors.add(:target_comment, 'must be present')
    end
  end
end
