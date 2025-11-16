# frozen_string_literal: true

module Reportable
  def self.included(base)
    base.has_many :received_reports, as: :reportable, class_name: 'Report', dependent: :destroy
  end

  def apply_decision!(decision)
    raise NotImplementedError, "#{self.class} must implement apply_decision!"
  end
end
