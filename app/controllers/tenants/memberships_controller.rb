# frozen_string_literal: true

module Tenants
  class MembershipsController < BaseController
    before_action :set_membership
    before_action -> { authorize_action!(@membership) }

    def edit; end

    def update
      if @membership.update(membership_params)
        flash[:notice] = t('flash.actions.update.notice', resource: TenantMembership.model_name.human)
        redirect_to edit_tenant_membership_path(tenant_slug: @membership.tenant.slug)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_membership
      return unless current_user

      @membership = current_user.tenant_memberships.find_by(tenant: current_tenant)
    end

    def membership_params
      params.expect(tenant_membership: [:display_name])
    end
  end
end
