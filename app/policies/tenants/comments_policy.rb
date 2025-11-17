# frozen_string_literal: true

module Tenants
  class CommentsPolicy < ApplicationPolicy
    def create? = active_tenant_member? && unsuspended_user?
    def edit? = active_tenant_member? && unsuspended_user? && owner?
    def update? = active_tenant_member? && unsuspended_user? && owner?
  end
end
