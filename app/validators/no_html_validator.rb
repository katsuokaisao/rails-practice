# frozen_string_literal: true

class NoHtmlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value.present? && value != ActionController::Base.helpers.strip_tags(value)

    record.errors.add(attribute, :html_not_allowed)
  end
end
