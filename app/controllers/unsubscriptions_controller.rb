# frozen_string_literal: true

class UnsubscriptionsController < ApplicationController
  before_action -> { authorize_action! }

  def new
    @active_memberships = current_user.tenant_memberships
                                      .active
                                      .includes(:tenant)
                                      .order(created_at: :desc)
  end

  def create
    tenant_ids = params[:tenant_ids] || []

    if tenant_ids.empty?
      redirect_to new_unsubscription_path, alert: t('.no_tenants_selected')
      return
    end

    valid_tenants = current_user.tenant_memberships
                                   .active
                                   .where(tenant_id: tenant_ids)

    if valid_tenants.empty?
      redirect_to new_unsubscription_path, alert: t('.invalid_tenant')
      return
    end

    valid_tenants.update!(unsubscribed_at: Time.current)

    UnsubscriptionJob.perform_later(current_user.id, valid_tenants.pluck(:tenant_id))

    redirect_to new_unsubscription_path, notice: t('.success')
  end
end
