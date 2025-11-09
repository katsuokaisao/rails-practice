# frozen_string_literal: true

# ユーザーモデル
#
# 会員ユーザに該当する。
# 掲示板にお題を投稿したり、お題に対してコメントを投稿したりできる。
# == Schema Information
#
# Table name: users
#
#  id                        :bigint           not null, primary key
#  encrypted_password        :string(255)      not null
#  pending_invitations_count :integer          default(0), not null
#  time_zone                 :string(255)      default("Tokyo"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  login_id                  :string(255)      not null
#
# Indexes
#
#  idx_users_login_id  (login_id) UNIQUE
#
class User < ApplicationRecord
  include AuthenticatableAccount
  include Reportable

  has_many :topics, foreign_key: 'author_id', dependent: :restrict_with_exception, inverse_of: :author
  has_many :authored_reports, class_name: 'Report', foreign_key: 'reporter_id',
                              dependent: :restrict_with_error, inverse_of: :reporter
  has_many :comments, foreign_key: 'author_id', dependent: :restrict_with_exception, inverse_of: :author
  has_many :tenant_memberships, dependent: :destroy
  has_many :tenants, through: :tenant_memberships
  has_many :sent_invitations,
           class_name: 'TenantInvitation', foreign_key: :inviter_id, dependent: :destroy,
           inverse_of: :inviter
  has_many :received_invitations,
           class_name: 'TenantInvitation', foreign_key: :invited_user_id, dependent: :destroy,
           inverse_of: :invited_user

  def apply_decision!(decision)
    suspend!(decision.tenant, decision.suspended_until) if decision.decision_type_suspend_user?
  end

  def suspended?(tenant)
    tenant_memberships.find_by(tenant: tenant)&.suspended? || false
  end

  def suspend!(tenant, suspended_until)
    tenant_memberships.find_by!(tenant: tenant).suspend!(suspended_until)
  end

  def suspended_until_date(tenant)
    tenant_memberships.find_by(tenant: tenant)&.suspended_until_date
  end

  def enforce_release_suspension!(tenant)
    tenant_memberships.find_by!(tenant: tenant).enforce_release_suspension!
  end

  def member_of?(tenant)
    tenant_memberships.exists?(tenant: tenant)
  end

  def display_name_for(tenant)
    membership = if association(:tenant_memberships).loaded?
                   tenant_memberships.detect { |tm| tm.tenant_id == tenant.id }
                 else
                   tenant_memberships.find_by(tenant: tenant)
                 end
    membership&.display_name || ''
  end

  def pending_invitations
    received_invitations.status_pending
  end

  def pending_invitations?
    pending_invitations.exists?
  end

  def memberships_ordered_by_tenant_name
    tenant_memberships.includes(:tenant).order('tenants.name')
  end
end
