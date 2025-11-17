# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    def set_current_tenant
      @current_tenant = Tenant.find(params[:id])
    end
  end
end
