# frozen_string_literal: true

# ユーザーモデル
#
# 会員ユーザに該当する。
# 掲示板にお題を投稿したり、お題に対してコメントを投稿したりできる。
# == Schema Information
#
# Table name: users
#
#  id                 :bigint           not null, primary key
#  encrypted_password :string(255)      not null
#  nickname           :string(255)      not null
#  suspended_until    :datetime
#  time_zone          :string(255)      default("Tokyo"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  idx_users_nickname  (nickname) UNIQUE
#
class User < ApplicationRecord
  NICKNAME_MIN_LENGTH = 1
  NICKNAME_MAX_LENGTH = 50
  PASSWORD_MIN_LENGTH = 8
  PASSWORD_MAX_LENGTH = 50
  PASSWORD_REGEX = /\A[!-~]+\z/ # Asciiの印刷可能文字(スペース含まない)のみ

  devise :database_authenticatable, :registerable

  has_many :topics, foreign_key: 'author_id', dependent: :restrict_with_exception, inverse_of: :author
  has_many :reports, class_name: 'Report', foreign_key: 'reporter_id',
                     dependent: :restrict_with_error, inverse_of: :reporter
  has_many :received_reports, class_name: 'Report', as: :target,
                              dependent: :restrict_with_error
  has_many :comments, foreign_key: 'author_id', dependent: :restrict_with_exception, inverse_of: :author

  before_validation :normalize_nickname

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

  def apply_decision!(decision)
    suspend!(decision.suspension_until)
  end

  def suspend!(suspended_until)
    update!(suspended_until: suspended_until)
  end

  def suspended?
    suspended_until.present? && suspended_until.future?
  end

  def suspended_until_date
    return unless suspended?

    suspended_until.to_date
  end

  def enforce_release_suspension!
    return unless suspended?

    update!(suspended_until: nil)
  end

  private

  def password_update?
    !new_record? && (password.present? || password_confirmation.present?)
  end

  def normalize_nickname
    return if nickname.nil?

    self.nickname = nickname.strip.squish
  end
end
