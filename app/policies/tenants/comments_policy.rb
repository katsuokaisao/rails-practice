# frozen_string_literal: true

module Tenants
  class CommentsPolicy < ApplicationPolicy
    def create?
      tenant_member? && unsuspended_user?
    end

    def edit?
      tenant_member? && unsuspended_user? && owner?
    end

    def update?
      tenant_member? && unsuspended_user? && owner?
    end
  end
end
