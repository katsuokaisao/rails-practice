# frozen_string_literal: true

module My
  class InvitationsController < ApplicationController
    before_action :set_invitation, except: %i[index]
    before_action -> { authorize_action!(@invitation) }
    before_action :verify_invitation_pending, except: %i[index]
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
      @tenant_membership = @invitation.accept!(display_name: display_name_param)

      flash[:notice] = t('.success', tenant_name: @invitation.tenant.name)
      redirect_to tenant_path(tenant_slug: @invitation.tenant.slug)
    rescue ActiveRecord::RecordInvalid => e
      @tenant_membership = e.record
      render :accept, status: :unprocessable_entity
    end

    def reject
      @invitation.reject!

      flash[:notice] = t('.success')
      redirect_to my_invitations_path
    rescue ActiveRecord::RecordInvalid
      flash[:alert] = t('flash.actions.create.alert', resource: TenantInvitation.model_name.human)
      redirect_to my_invitations_path
    end

    private

    def set_invitation
      @invitation = current_user.received_invitations.find(params[:id])
    end

    def display_name_param
      params.expect(tenant_membership: [:display_name])[:display_name]
    end

    def verify_invitation_pending
      return if @invitation.status_pending?

      flash[:alert] = t('my.invitations.errors.already_processed')
      redirect_to my_invitations_path
    end

    def verify_not_member
      return unless @invitation.already_member?

      flash[:alert] = t('my.invitations.errors.already_member')
      redirect_to my_invitations_path
    end
  end
end
