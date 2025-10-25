# frozen_string_literal: true

class TenantsController < ApplicationController
  include TenantScoped

  before_action :require_tenant, only: %i[show]

  def index
    @tenants = Tenant.order(:identifier)
  end

  def show
    @tenant = current_tenant
  end
end
