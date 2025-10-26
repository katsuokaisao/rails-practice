# frozen_string_literal: true

class TenantProfilesPolicy < ApplicationPolicy
  def edit?
    membership_owner?
  end

  def update?
    membership_owner?
  end
end
