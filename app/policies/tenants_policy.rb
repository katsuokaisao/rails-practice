# frozen_string_literal: true

class TenantsPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end
end
