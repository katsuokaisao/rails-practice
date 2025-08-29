# frozen_string_literal: true

class DecisionsPolicy < ApplicationPolicy
  def new? = moderator?
  def create? = moderator?
end
