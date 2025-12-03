# frozen_string_literal: true

module Tenants
  class ReportsPolicy < ApplicationPolicy
    def index?
      moderator_tenant_member?
    end

    def new?
      active_tenant_member? && unsuspended_user? && !owner?
    end

    def create?
      active_tenant_member? && unsuspended_user? && !owner?
    end
  end
end
