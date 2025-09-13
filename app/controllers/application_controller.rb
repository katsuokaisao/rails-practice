# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authorization

  before_action :set_time_zone

  helper_method :only_user_signed_in?

  # 403
  rescue_from Authorization::NotAuthorizedError, with: :render_forbidden

  def only_user_signed_in?
    user_signed_in? && !moderator_signed_in?
  end

  private

  def set_time_zone
    if moderator_signed_in? && current_moderator.time_zone.present?
      Time.zone = current_moderator.time_zone
    elsif user_signed_in? && current_user.time_zone.present?
      Time.zone = current_user.time_zone
    end
  end

  def user_time_zone_identifier
    Time.zone&.tzinfo&.identifier || 'UTC'
  end

  def render_forbidden
    render file: Rails.public_path.join('403.html'), status: :forbidden, layout: false, content_type: 'text/html'
  end
end
