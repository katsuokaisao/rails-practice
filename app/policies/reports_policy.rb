# frozen_string_literal: true

class ReportsPolicy < ApplicationPolicy
  def index? = moderator?
  def new? = unsuspended_user?
  def create? = unsuspended_user?
end
