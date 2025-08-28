# frozen_string_literal: true

class ReportsPolicy < ApplicationPolicy
  def index? = moderator?
  def new? = user?
  def create? = user?
end
