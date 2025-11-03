# frozen_string_literal: true

module Tenants
  class BaseController < ApplicationController
    before_action :require_tenant
  end
end
