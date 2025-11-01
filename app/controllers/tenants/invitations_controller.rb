# frozen_string_literal: true

module Tenants
  class InvitationsController < ApplicationController
    include TenantScoped

    before_action :require_tenant

    def new
      @invitation = current_tenant.tenant_invitations.build
    end

    def create
      @invitation = current_tenant.tenant_invitations.build(invitation_params)
      @invitation.inviter = current_user

      if @invitation.save
        flash[:notice] = t('.success', resource: TenantInvitation.model_name.human)
        redirect_to tenant_root_path(tenant_slug: current_tenant.identifier)
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def invitation_params
      params.expect(tenant_invitation: [:invited_user_id])
    end
  end
end
