# frozen_string_literal: true

module Tenants
  class DecisionsPolicy < ApplicationPolicy
    def index?
      moderator_tenant_member?
    end

    def new?
      moderator_tenant_member?
    end

    def create?
      moderator_tenant_member?
    end
  end
end
