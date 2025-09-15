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
  include AuthenticatableAccount
  include Reportable

  has_many :topics, foreign_key: 'author_id', dependent: :restrict_with_exception, inverse_of: :author
  has_many :authored_reports, class_name: 'Report', foreign_key: 'reporter_id',
                              dependent: :restrict_with_error, inverse_of: :reporter
  has_many :comments, foreign_key: 'author_id', dependent: :restrict_with_exception, inverse_of: :author

  validate :suspended_until_future, if: -> { suspended_until.present? }

  def apply_decision!(decision)
    suspend!(decision.suspended_until)
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

  def suspended_until_future
    errors.add(:suspended_until, :must_be_in_future) unless suspended_until.future?
  end
end
