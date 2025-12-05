# frozen_string_literal: true

class TenantInvitationDecorator < ApplicationDecorator
  decorates_association :inviter
end
