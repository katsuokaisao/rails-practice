# frozen_string_literal: true

class TenantsController < ApplicationController
  before_action :require_tenant, only: %i[show]

  def index
    if user_signed_in?
      member_tenants_relation = current_user.tenants.order(id: :desc)
      other_tenants_relation = Tenant.where.not(id: member_tenants_relation.pluck(:id)).order(id: :desc)
    else
      member_tenants_relation = Tenant.none
      other_tenants_relation = Tenant.order(id: :desc)
    end

    @member_pagination = Pagination::Paginator.new(
      relation: member_tenants_relation,
      page: params[:member_page],
      per: params[:per] || 10
    ).call

    @other_pagination = Pagination::Paginator.new(
      relation: other_tenants_relation,
      page: params[:other_page],
      per: params[:per] || 10
    ).call

    return unless @member_pagination.out_of_bounds || @other_pagination.out_of_bounds

    redirect_to root_path, alert: t('flash.actions.out_of_bounds')
  end

  def show
    @tenant = current_tenant

    @pagination = Pagination::Paginator.new(
      relation: topics, page: params[:page], per: params[:per]
    ).call

    return unless @pagination.out_of_bounds

    flash[:alert] = t('flash.actions.out_of_bounds')
    redirect_to tenant_path(tenant_slug: current_tenant.slug)
  end

  private

  def topics
    current_tenant.topics
      .order(created_at: :desc, id: :desc)
      .eager_load(:author)
  end
end
