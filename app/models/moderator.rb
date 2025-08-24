# frozen_string_literal: true

# モデレーターモデル
#
# 管理者ユーザのこと
# 通報の結果を審査するのが主な役割
class Moderator < ApplicationRecord
  NICKNAME_MIN_LENGTH = 1
  NICKNAME_MAX_LENGTH = 50
  PASSWORD_MIN_LENGTH = 1
  PASSWORD_MAX_LENGTH = 50

  devise :database_authenticatable

  validates :nickname, presence: true, uniqueness: true
  validates :nickname, length: { minimum: NICKNAME_MIN_LENGTH, maximum: NICKNAME_MAX_LENGTH, allow_blank: true }

  # moderator account update: current_password, password, password_confirmation
  with_options if: -> { password_update? } do
    validates :password, presence: true, confirmation: true
    validates :password, length: { minimum: PASSWORD_MIN_LENGTH, maximum: PASSWORD_MAX_LENGTH, allow_blank: true }
  end

  private

  def password_update?
    !new_record? && (password.present? || password_confirmation.present?)
  end
end
