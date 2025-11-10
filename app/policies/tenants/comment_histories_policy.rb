# frozen_string_literal: true

module Tenants
  class CommentHistoriesPolicy < ApplicationPolicy
    def index? = (tenant_member? && owner?) || moderator?
    def compare? = (tenant_member? && owner?) || moderator?
  end
end
