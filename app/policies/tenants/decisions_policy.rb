# frozen_string_literal: true

module Tenants
  class DecisionsPolicy < ApplicationPolicy
    def index? = moderator? && moderator_tenant_member?
    def new? = moderator? && moderator_tenant_member?
    def create? = moderator? && moderator_tenant_member?
  end
end
