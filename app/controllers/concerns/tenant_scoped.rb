# frozen_string_literal: true

module TenantScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_current_tenant
    helper_method :current_tenant
  end

  private

  def set_current_tenant
    return if params[:tenant_slug].blank?

    @current_tenant = Tenant.find_by!(identifier: params[:tenant_slug])
  end

  def current_tenant
    @current_tenant
  end

  def require_tenant
    return if current_tenant.present?

    redirect_to root_path, alert: t('flash.actions.tenant_missing')
  end
end
