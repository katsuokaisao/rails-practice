# frozen_string_literal: true

module Tenants
  class BanReasonsPolicy < ApplicationPolicy
    def index?
      moderator_tenant_member?
    end

    def new?
      moderator_tenant_member?
    end

    def create?
      moderator_tenant_member?
    end

    def edit?
      moderator_tenant_member?
    end

    def update?
      moderator_tenant_member?
    end

    def destroy?
      moderator_tenant_member?
    end
  end
end
