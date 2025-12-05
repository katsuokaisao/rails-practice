# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :set_current_tenant

    def set_current_tenant
      @current_tenant = Tenant.find(params[:id])
    end
  end
end
