# frozen_string_literal: true

module Tenants
  class ReportsPolicy < ApplicationPolicy
    def index?
      moderator_tenant_member?
    end

    def new?
      tenant_member? && unsuspended_user? && !owner?
    end

    def create?
      tenant_member? && unsuspended_user? && !owner?
    end
  end
end
