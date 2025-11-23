# frozen_string_literal: true

module Tenants
  class TopicsPolicy < ApplicationPolicy
    def show? = true
    def new? = active_tenant_member? && unsuspended_user?
    def create? = active_tenant_member? && unsuspended_user?
    def edit? = active_tenant_member? && unsuspended_user? && owner? && !topic_locked?
    def update? = active_tenant_member? && unsuspended_user? && owner? && !topic_locked?
  end
end
