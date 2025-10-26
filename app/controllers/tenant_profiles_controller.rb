# frozen_string_literal: true

class TenantProfilesController < ApplicationController
  include TenantScoped

  before_action :require_tenant
  before_action :set_membership

  def edit; end

  def update
    if @membership.update(membership_params)
      redirect_to tenant_users_profile_path(@membership.tenant.identifier),
                  notice: t('flash.actions.update.notice', resource: Tenant.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_membership
    @membership = current_user.tenant_memberships.find_by!(tenant: current_tenant)
  end

  def membership_params
    params.expect(tenant_membership: [:display_name])
  end
end
