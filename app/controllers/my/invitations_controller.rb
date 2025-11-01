# frozen_string_literal: true

module My
  class InvitationsController < ApplicationController
    before_action :set_invitation, except: %i[index]
    before_action :verify_invitation_status, except: %i[index]
    before_action :verify_not_member, except: %i[index]

    def index
      @invitations = current_user.received_invitations
                                 .status_pending
                                 .includes(:tenant, :inviter)
                                 .recent
    end

    def accept
      @tenant_membership = current_user.tenant_memberships.new(
        tenant: @invitation.tenant
      )
    end

    def create_acceptance
      @tenant_membership = current_user.tenant_memberships.new(
        tenant: @invitation.tenant,
        display_name: display_name_param
      )

      ActiveRecord::Base.transaction do
        @tenant_membership.save!
        @invitation.status_accepted!
      end

      flash[:notice] = t('.success', tenant_name: @invitation.tenant.name)
      redirect_to tenant_root_path(tenant_slug: @invitation.tenant.identifier)
    rescue ActiveRecord::RecordInvalid
      render :accept, status: :unprocessable_entity
    end

    def reject
      @invitation.status_rejected!
      flash[:notice] = t('.success')
      redirect_to my_invitations_path
    end

    private

    def set_invitation
      @invitation = current_user.received_invitations.find(params[:id])
    end

    def verify_invitation_status
      return if @invitation.status_pending?

      flash[:alert] = t('my.invitations.errors.invalid_invitation')
      redirect_to my_invitations_path
    end

    def verify_not_member
      return unless current_user.member_of?(@invitation.tenant)

      flash[:alert] = t('my.invitations.errors.already_member')
      redirect_to my_invitations_path
    end

    def display_name_param
      params.expect(tenant_membership: [:display_name])[:display_name]
    end
  end
end
