# frozen_string_literal: true

class UnsubscriptionsController < ApplicationController
  before_action -> { authorize_action! }

  def new
    @subscribed_memberships = current_user
                              .subscribed_tenant_memberships
                              .includes(:tenant)
                              .order(created_at: :desc)
  end

  def create
    tenant_ids = unsubscription_params[:tenant_ids] || []

    if tenant_ids.empty?
      redirect_to new_unsubscription_path, alert: t('.no_tenants_selected')
      return
    end

    subscribed_tenant_memberships = current_user
                                    .subscribed_tenant_memberships
                                    .where(tenant_id: tenant_ids)

    if subscribed_tenant_memberships.empty?
      redirect_to new_unsubscription_path, alert: t('.invalid_tenant')
      return
    end

    subscribed_tenant_memberships.update!(unsubscribed_at: Time.current)

    UnsubscriptionJob.perform_later(current_user.id, subscribed_tenant_memberships.pluck(:tenant_id))

    redirect_to new_unsubscription_path, notice: t('.success')
  end

  private

  def unsubscription_params
    params.permit(tenant_ids: [])
  end
end
