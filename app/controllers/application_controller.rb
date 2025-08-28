# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authorization

  rescue_from Authorization::NotAuthorizedError do
    forbidden
  end

  private

  def current_actor
    current_moderator || current_user
  end

  def not_found
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false, content_type: 'text/html'
  end

  def forbidden
    render file: Rails.public_path.join('403.html'), status: :forbidden, layout: false, content_type: 'text/html'
  end

  def unprocessable_entity
    render file: Rails.public_path.join('422.html'), status: :unprocessable_entity, layout: false,
           content_type: 'text/html'
  end

  def internal_server_error
    render file: Rails.public_path.join('500.html'), status: :internal_server_error, layout: false,
           content_type: 'text/html'
  end
end
