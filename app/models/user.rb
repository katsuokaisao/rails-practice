# frozen_string_literal: true

class User < ApplicationRecord
  NICKNAME_MIN_LENGTH = 1
  NICKNAME_MAX_LENGTH = 50
  PASSWORD_MIN_LENGTH = 1
  PASSWORD_MAX_LENGTH = 50

  devise :database_authenticatable, :registerable

  validates_presence_of     :nickname
  validates_uniqueness_of   :nickname
  validates_length_of       :nickname, minimum: NICKNAME_MIN_LENGTH, maximum: NICKNAME_MAX_LENGTH, allow_blank: true

  # user sign up: password, password_confirmation
  # user account update: current_password, password, password_confirmation
  with_options if: -> { new_record? || password_update? } do
    validates_confirmation_of :password
    validates_presence_of     :password
    validates_length_of       :password, minimum: PASSWORD_MIN_LENGTH, maximum: PASSWORD_MAX_LENGTH, allow_blank: true
  end

  private

  def password_update?
    !new_record? && (password.present? || password_confirmation.present?)
  end
end
