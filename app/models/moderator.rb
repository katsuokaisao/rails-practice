# frozen_string_literal: true

# モデレーターモデル
#
# 管理者ユーザのこと
# 通報の結果を審査するのが主な役割
# == Schema Information
#
# Table name: moderators
#
#  id                 :bigint           not null, primary key
#  encrypted_password :string(255)      not null
#  nickname           :string(255)      not null
#  time_zone          :string(255)      default("Tokyo"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  idx_moderators_nickname  (nickname) UNIQUE
#
class Moderator < ApplicationRecord
  NICKNAME_MIN_LENGTH = 1
  NICKNAME_MAX_LENGTH = 50
  PASSWORD_MIN_LENGTH = 8
  PASSWORD_MAX_LENGTH = 50
  PASSWORD_REGEX = /\A[!-~]+\z/ # Asciiの印刷可能文字(スペース含まない)のみ

  devise :database_authenticatable, :registerable

  has_many :decisions, foreign_key: 'decided_by', inverse_of: :moderator, dependent: :nullify

  validates :nickname, presence: true, uniqueness: true,
                       length: { minimum: NICKNAME_MIN_LENGTH, maximum: NICKNAME_MAX_LENGTH, allow_blank: true }
  validates :time_zone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  # user sign up: password, password_confirmation
  # user account update: current_password, password, password_confirmation
  with_options if: -> { new_record? || password_update? } do
    validates :password, presence: true, confirmation: true
    validates :password, length: { minimum: PASSWORD_MIN_LENGTH, maximum: PASSWORD_MAX_LENGTH },
                         format: { with: PASSWORD_REGEX }, allow_blank: true
  end

  private

  def password_update?
    !new_record? && (password.present? || password_confirmation.present?)
  end
end
