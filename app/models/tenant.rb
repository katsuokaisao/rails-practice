# frozen_string_literal: true

# == Schema Information
#
# Table name: tenants
#
#  id                          :bigint           not null, primary key
#  description(テナントの説明) :text(65535)      not null
#  identifier(テナント識別子)  :string(255)      not null
#  name(テナント名（表示用）)  :string(255)      not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  idx_tenants_identifier  (identifier) UNIQUE
#  idx_tenants_name        (name)
#
class Tenant < ApplicationRecord
  validates :name, presence: true, length: { maximum: 100 }

  validates :identifier,
            presence: true,
            uniqueness: true,
            length: { maximum: 50 },
            format: {
              with: /\A[a-z0-9-]+\z/
            }

  validates :description, presence: true, length: { maximum: 500 }
end
