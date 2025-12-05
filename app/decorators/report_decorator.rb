# frozen_string_literal: true

class ReportDecorator < ApplicationDecorator
  decorates_association :reporter
  decorates_association :reportable
  decorates_association :ban_reason

  def reason_type
    ban_reason.display_name
  end
end
