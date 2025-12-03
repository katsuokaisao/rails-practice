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
#  time_zone          :string(255)      default("Tokyo"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  login_id           :string(255)      not null
#  tenant_id          :bigint           not null
#
# Indexes
#
#  idx_moderators_login_id   (login_id) UNIQUE
#  idx_moderators_tenant_id  (tenant_id)
#
class Moderator < ApplicationRecord
  include AuthenticatableAccount

  belongs_to :tenant
  has_many :decisions, foreign_key: 'decided_by', inverse_of: :decider, dependent: :nullify

  def member_of?(tenant)
    tenant_id == tenant.id
  end
end
