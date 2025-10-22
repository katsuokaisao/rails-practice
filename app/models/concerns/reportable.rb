# frozen_string_literal: true

module Reportable
  def self.included(base)
    base.has_many :received_reports, as: :reportable, dependent: :restrict_with_error
  end

  def apply_decision!(decision)
    raise NotImplementedError, "#{self.class} must implement apply_decision!"
  end
end
