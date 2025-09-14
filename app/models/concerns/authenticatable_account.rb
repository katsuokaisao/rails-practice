# frozen_string_literal: true

module AuthenticatableAccount
  extend ActiveSupport::Concern

  NICKNAME_MIN_LENGTH = 1
  NICKNAME_MAX_LENGTH = 50
  PASSWORD_MIN_LENGTH = 8
  PASSWORD_MAX_LENGTH = 50
  PASSWORD_REGEX = /\A[!-~]+\z/ # Asciiの印刷可能文字(スペース含まない)のみ
  TIME_ZONE_NAMES = ActiveSupport::TimeZone.all.map(&:name).freeze

  included do
    devise :database_authenticatable, :registerable

    before_validation :normalize_nickname

    validates :nickname, presence: true, uniqueness: true,
                         length: { minimum: NICKNAME_MIN_LENGTH, maximum: NICKNAME_MAX_LENGTH, allow_blank: true }

    # user sign up: password, password_confirmation
    # user account update: current_password, password, password_confirmation
    with_options if: -> { require_password_validations? } do
      validates :password, presence: true, confirmation: true
      validates :password, length: { minimum: PASSWORD_MIN_LENGTH, maximum: PASSWORD_MAX_LENGTH },
                           format: { with: PASSWORD_REGEX }, allow_blank: true
    end

    validates :time_zone, presence: true, inclusion: { in: TIME_ZONE_NAMES }

    private

    def require_password_validations?
      new_record? || password_update?
    end

    def password_update?
      !new_record? && (password.present? || password_confirmation.present?)
    end

    def normalize_nickname
      return if nickname.nil?

      self.nickname = nickname.strip.squish
    end
  end
end
