# frozen_string_literal: true

class TopicsPolicy < ApplicationPolicy
  def index? = true
  def show? = true
  def new? = unsuspended_user?
  def create? = unsuspended_user?
  def edit? = unsuspended_user? && owner?
  def update? = unsuspended_user? && owner?
end
