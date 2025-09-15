# frozen_string_literal: true

class ReportsPolicy < ApplicationPolicy
  def index? = moderator?
  def new? = unsuspended_user? && !owner?
  def create? = unsuspended_user? && !owner?

  private

  def owner?
    return comment_owner?(record) if record.is_a?(Comment)
    return report_owner?(record)  if record.is_a?(Report)

    false
  end

  def comment_owner?(comment)
    comment.author_id == user.id
  end

  def report_owner?(report)
    return report.reportable&.author_id == user.id if report.reportable_type == 'comment'
    return report.reportable&.id == user.id if report.reportable_type == 'user'

    false
  end
end
