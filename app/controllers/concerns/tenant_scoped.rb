# frozen_string_literal: true

module TenantScoped
  extend ActiveSupport::Concern

  included do
    helper_method :current_tenant
  end

  private

  def set_current_tenant
    return if params[:tenant_slug].blank?

    @current_tenant = Tenant.find_by!(slug: params[:tenant_slug])
  end

  def current_tenant
    @current_tenant
  end
end
