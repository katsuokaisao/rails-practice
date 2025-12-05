# frozen_string_literal: true

module Admin
  class TenantsPolicy < ApplicationPolicy
    def edit?
      moderator_tenant_member?
    end

    def update?
      edit?
    end
  end
end
