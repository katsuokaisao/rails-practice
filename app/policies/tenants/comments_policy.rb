# frozen_string_literal: true

module Tenants
  class CommentsPolicy < ApplicationPolicy
    def create? = tenant_member? && unsuspended_user?
    def edit? = tenant_member? && unsuspended_user? && owner?
    def update? = tenant_member? && unsuspended_user? && owner?
  end
end
