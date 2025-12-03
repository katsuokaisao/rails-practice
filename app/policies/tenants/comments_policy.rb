# frozen_string_literal: true

module Tenants
  class CommentsPolicy < ApplicationPolicy
    def create?
      active_tenant_member? && unsuspended_user? && !topic_locked?
    end

    def edit?
      active_tenant_member? && unsuspended_user? && owner? && !topic_locked?
    end

    def update?
      active_tenant_member? && unsuspended_user? && owner? && !topic_locked?
    end

    private

    def topic_locked?
      topic = record.is_a?(Topic) ? record : record.topic
      topic.locked?
    end
  end
end
