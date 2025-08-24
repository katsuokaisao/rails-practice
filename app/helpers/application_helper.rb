# frozen_string_literal: true

module ApplicationHelper
  def root_class_name
    [data_controller_name, data_action_name].join(' ')
  end

  def data_controller_name
    "#{controller_path.gsub('/', '_')}_controller"
  end

  def data_action_name
    "#{action_name}_action"
  end
end
