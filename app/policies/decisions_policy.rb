# frozen_string_literal: true

class DecisionsPolicy < ApplicationPolicy
  def index? = moderator?
  def new? = moderator?
  def create? = moderator?
end
