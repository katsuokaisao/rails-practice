# frozen_string_literal: true

module Tenants
  class ReportsPolicy < ApplicationPolicy
    def index? = moderator? && moderator_tenant_member?
    def new? = active_tenant_member? && unsuspended_user? && !owner?
    def create? = active_tenant_member? && unsuspended_user? && !owner?
  end
end
