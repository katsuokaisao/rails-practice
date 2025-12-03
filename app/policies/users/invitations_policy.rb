# frozen_string_literal: true

module Users
  class InvitationsPolicy < ApplicationPolicy
    def index?
      user?
    end

    def accept?
      user? && invitation_recipient?
    end

    def create_acceptance?
      user? && invitation_recipient?
    end

    def reject?
      user? && invitation_recipient?
    end

    private

    def invitation_recipient?
      return false unless record.is_a?(TenantInvitation)

      record.invited_user == user
    end
  end
end
