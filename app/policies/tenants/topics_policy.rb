# frozen_string_literal: true

module Tenants
  class TopicsPolicy < ApplicationPolicy
    def show?
      true
    end

    def new?
      active_tenant_member? && unsuspended_user?
    end

    def create?
      active_tenant_member? && unsuspended_user?
    end

    def edit?
      active_tenant_member? && unsuspended_user? && owner? && !topic_locked?
    end

    def update?
      active_tenant_member? && unsuspended_user? && owner? && !topic_locked?
    end

    private

    def topic_locked?
      record.locked?
    end
  end
end
