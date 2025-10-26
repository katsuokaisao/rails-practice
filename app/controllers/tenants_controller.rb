# frozen_string_literal: true

class TenantsController < ApplicationController
  include TenantScoped

  before_action :require_tenant, only: %i[show]

  def index
    @pagination = Pagination::Paginator.new(
      relation: tenants, page: params[:page], per: params[:per]
    ).call

    redirect_to root_path, alert: t('flash.actions.out_of_bounds') if @pagination.out_of_bounds
  end

  def show
    @tenant = current_tenant
  end

  private

  def tenants
    Tenant.order(created_at: :desc)
  end
end
