# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authorization
  include TenantScoped

  before_action :set_time_zone

  # 403
  rescue_from Authorization::NotAuthorizedError, with: :render_forbidden

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

  def preload_current_user_memberships
    current_user&.tenant_memberships&.load
  end
end
