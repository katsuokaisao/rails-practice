# frozen_string_literal: true

class CommentHistoriesPolicy < ApplicationPolicy
  def index? = owner? || moderator?
  def compare? = owner? || moderator?
end
