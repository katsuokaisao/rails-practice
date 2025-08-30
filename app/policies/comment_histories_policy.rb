# frozen_string_literal: true

class CommentHistoriesPolicy < ApplicationPolicy
  def index? = owner?
  def compare? = owner?
end
