# frozen_string_literal: true

module Tenants
  class UsersController < ApplicationController
    include TenantScoped

    before_action :require_tenant
    before_action :set_user

    def show
      @membership = current_tenant.tenant_memberships.find_by!(user: @user)
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
