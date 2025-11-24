# frozen_string_literal: true

module Tenants
  class BaseController < ApplicationController
    before_action :set_current_tenant
  end
end
