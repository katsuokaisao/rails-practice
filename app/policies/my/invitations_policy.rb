# frozen_string_literal: true

module My
  class InvitationsPolicy < ApplicationPolicy
    def index?
      user?
    end

    def accept?
      unsuspended_user? && invitation_recipient?
    end

    def create_acceptance?
      unsuspended_user? && invitation_recipient?
    end

    def reject?
      unsuspended_user? && invitation_recipient?
    end

    private

    def invitation_recipient?
      return false unless record.is_a?(TenantInvitation)

      record.invited_user == user
    end
  end
end
