# frozen_string_literal: true

class BanReasonDecorator < ApplicationDecorator
  def display_name
    system? ? I18n.t("ban_reasons.system.#{name}") : name
  end

  def display_description
    system? ? I18n.t("ban_reasons.system_descriptions.#{name}") : description
  end
end
