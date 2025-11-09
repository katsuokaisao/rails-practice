# frozen_string_literal: true

module Tenants
  class ReportsPolicy < ApplicationPolicy
    def index? = moderator? && moderator_tenant_member?
    def new? = tenant_member? && unsuspended_user? && !owner?
    def create? = tenant_member? && unsuspended_user? && !owner?
  end
end
