# frozen_string_literal: true

module Tenants
  class InvitationsPolicy < ApplicationPolicy
    def new?
      unsuspended_user? && active_tenant_member?
    end

    def create?
      unsuspended_user? && active_tenant_member?
    end
  end
end
