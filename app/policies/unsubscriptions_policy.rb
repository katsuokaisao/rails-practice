# frozen_string_literal: true

class UnsubscriptionsPolicy < ApplicationPolicy
  def new?
    user?
  end

  def create?
    user?
  end
end
