# frozen_string_literal: true

module Tenants
  class InvitationsPolicy < ApplicationPolicy
    def new?
      unsuspended_user? && tenant_member?
    end

    def create?
      unsuspended_user? && tenant_member?
    end
  end
end
