# frozen_string_literal: true

module My
  class InvitationsController < ApplicationController
    def index
      @invitations = current_user.received_invitations
                                 .status_pending
                                 .includes(:tenant, :inviter)
                                 .recent
    end
  end
end
