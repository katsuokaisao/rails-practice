# frozen_string_literal: true

module Tenants
  class MembershipsPolicy < ApplicationPolicy
    def edit?
      membership_owner?
    end

    def update?
      membership_owner?
    end
  end
end
