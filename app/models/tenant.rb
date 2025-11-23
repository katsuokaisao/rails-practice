# frozen_string_literal: true

# == Schema Information
#
# Table name: tenants
#
#  id                          :bigint           not null, primary key
#  description(テナントの説明) :text(65535)      not null
#  name(テナント名（表示用）)  :string(255)      not null
#  slug(テナント識別子)        :string(255)      not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  idx_tenants_name  (name)
#  idx_tenants_slug  (slug) UNIQUE
#
class Tenant < ApplicationRecord
  has_many :tenant_memberships, dependent: :destroy
  has_many :members, through: :tenant_memberships, source: :user
  has_many :tenant_invitations, dependent: :destroy

  has_many :topics, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :decisions, dependent: :destroy
  has_many :moderators, dependent: :destroy
  has_many :ban_reasons, dependent: :destroy

  after_create :create_default_ban_reasons

  validates :name, presence: true, length: { maximum: 100 }

  validates :slug,
            presence: true,
            uniqueness: true,
            length: { maximum: 50 },
            format: {
              with: /\A[a-z0-9-]+\z/
            }

  validates :description, presence: true, length: { maximum: 500 }

  def member?(user)
    return false if user.nil?

    tenant_memberships.exists?(user: user)
  end

  private

  def create_default_ban_reasons
    default_reasons = [
      { name: 'spam', system: true },
      { name: 'harassment', system: true },
      { name: 'obscene', system: true },
      { name: 'other', system: true }
    ]

    default_reasons.each do |reason_attrs|
      ban_reasons.create!(reason_attrs)
    end
  end
end
