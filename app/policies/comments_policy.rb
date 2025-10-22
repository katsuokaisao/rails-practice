# frozen_string_literal: true

class CommentsPolicy < ApplicationPolicy
  def create? = unsuspended_user?
  def edit? = unsuspended_user? && owner?
  def update? = unsuspended_user? && owner?
end
