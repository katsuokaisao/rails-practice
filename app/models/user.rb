# frozen_string_literal: true

# ユーザーモデル
#
# 会員ユーザに該当する。
# 掲示板にお題を投稿したり、お題に対してコメントを投稿したりできる。
class User < ApplicationRecord
  NICKNAME_MIN_LENGTH = 1
  NICKNAME_MAX_LENGTH = 50
  PASSWORD_MIN_LENGTH = 8
  PASSWORD_MAX_LENGTH = 50
  PASSWORD_REGEX = /\A[!-~]+\z/ # Asciiの印刷可能文字(スペース含まない)のみ

  devise :database_authenticatable, :registerable

  has_many :topics, foreign_key: 'author_id', dependent: :restrict_with_exception, inverse_of: :author

  validates :nickname, presence: true, uniqueness: true,
                       length: { minimum: NICKNAME_MIN_LENGTH, maximum: NICKNAME_MAX_LENGTH, allow_blank: true }

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
