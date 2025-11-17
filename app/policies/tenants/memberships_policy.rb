# frozen_string_literal: true

module Tenants
  class MembershipsPolicy < ApplicationPolicy
    def edit?
      membership_owner? && active_tenant_member?
    end

    def update?
      membership_owner? && active_tenant_member?
    end
  end
end
