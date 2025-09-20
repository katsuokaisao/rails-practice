# frozen_string_literal: true

class ReportsPolicy < ApplicationPolicy
  def index? = moderator?
  def new? = unsuspended_user? && !owner?
  def create? = unsuspended_user? && !owner?
end
