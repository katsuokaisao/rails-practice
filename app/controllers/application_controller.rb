# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authorization

  helper_method :only_user_signed_in?

  # 403
  rescue_from Authorization::NotAuthorizedError, with: :render_forbidden

  # 404
  rescue_from ActiveRecord::RecordNotFound,               with: :render_not_found
  rescue_from AbstractController::ActionNotFound,         with: :render_not_found

  # 406
  rescue_from ActionController::UnknownFormat,            with: :render_not_acceptable

  # 409
  rescue_from ActiveRecord::RecordNotUnique,              with: :render_conflict
  rescue_from ActiveRecord::Deadlocked,                   with: :render_conflict
  rescue_from ActiveRecord::LockWaitTimeout,              with: :render_conflict

  # 422
  rescue_from ActiveRecord::RecordInvalid,                with: :render_unprocessable_entity

  def only_user_signed_in?
    user_signed_in? && !moderator_signed_in?
  end

  private

  def render_forbidden
    render file: Rails.public_path.join('403.html'), status: :forbidden, layout: false, content_type: 'text/html'
  end

  def render_not_found
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false, content_type: 'text/html'
  end

  def render_not_acceptable
    render file: Rails.public_path.join('406.html'), status: :not_acceptable, layout: false, content_type: 'text/html'
  end

  def render_conflict
    render file: Rails.public_path.join('409.html'), status: :conflict, layout: false, content_type: 'text/html'
  end

  def render_unprocessable_entity
    render file: Rails.public_path.join('422.html'),
           status: :unprocessable_entity, layout: false, content_type: 'text/html'
  end

  def render_internal_server_error
    render file: Rails.public_path.join('500.html'),
           status: :internal_server_error, layout: false, content_type: 'text/html'
  end
end
