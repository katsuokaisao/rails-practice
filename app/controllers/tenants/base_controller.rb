# frozen_string_literal: true

module Tenants
  class BaseController < ApplicationController
    before_action :set_current_tenant
    before_action :preload_current_user_memberships
  end
end
