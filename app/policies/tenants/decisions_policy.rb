# frozen_string_literal: true

module Tenants
  class DecisionsPolicy < ApplicationPolicy
    def index? = moderator_tenant_member?
    def new? = moderator_tenant_member?
    def create? = moderator_tenant_member?
  end
end
