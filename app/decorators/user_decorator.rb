# frozen_string_literal: true

class UserDecorator < ApplicationDecorator
  def display_name_for(tenant)
    membership = membership_for(tenant)
    if membership&.unsubscribed?
      I18n.t('activerecord.attributes.user.unsubscribed_user')
    else
      membership&.display_name || ''
    end
  end
end
