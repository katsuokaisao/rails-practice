# frozen_string_literal: true

# == Schema Information
#
# Table name: reports
#
#  id                                      :bigint           not null, primary key
#  reason_text                             :text(65535)      not null
#  reason_type                             :string(255)      not null
#  target_type((enum: 'comment' | 'user')) :string(255)      not null
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  reporter_id                             :bigint           not null
#  target_comment_id                       :bigint
#  target_user_id                          :bigint
#
# Indexes
#
#  idx_reports_reporter_id             (reporter_id)
#  idx_reports_target_comment_id       (target_comment_id)
#  idx_reports_target_type_created_at  (target_type,created_at)
#  idx_reports_target_user_id          (target_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (reporter_id => users.id)
#  fk_rails_...  (target_comment_id => comments.id)
#  fk_rails_...  (target_user_id => users.id)
#
class Report < ApplicationRecord
  belongs_to :reporter, class_name: 'User'
  belongs_to :target_user, class_name: 'User', optional: true
  belongs_to :target_comment, class_name: 'Comment', optional: true
  has_one :decision, dependent: :restrict_with_error

  scope :same_comment_as, lambda { |target_comment_id|
    where(target_comment_id: target_comment_id, target_type: 'comment')
  }

  scope :same_user_as, lambda { |target_user_id|
    where(target_user_id: target_user_id, target_type: 'user')
  }

  scope :without_report, ->(report) { where.not(id: report.id) }

  validates :target_type, presence: true, inclusion: { in: %w[comment user] }
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
    if target_type == 'user' && target_user.nil?
      errors.add(:target_user, 'must be present')
    elsif target_type == 'comment' && target_comment.nil?
      errors.add(:target_comment, 'must be present')
    end
  end
end
