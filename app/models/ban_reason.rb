# frozen_string_literal: true

# == Schema Information
#
# Table name: ban_reasons
#
#  id                               :bigint           not null, primary key
#  active                           :boolean          default(TRUE), not null
#  description                      :text(65535)
#  name                             :string(255)      not null
#  system(システム基本理由かどうか) :boolean          default(FALSE), not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  tenant_id                        :bigint           not null
#
# Indexes
#
#  idx_ban_reasons_tenant_id_active  (tenant_id,active)
#  uniq_ban_reasons_tenant_name      (tenant_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (tenant_id => tenants.id)
#
class BanReason < ApplicationRecord
  belongs_to :tenant
  has_many :reports, dependent: :restrict_with_error

  scope :active_reasons, -> { where(active: true) }
  scope :system_reasons, -> { where(system: true) }
  scope :custom_reasons, -> { where(system: false) }

  validates :name, presence: true, uniqueness: { scope: :tenant_id }
  validates :active, inclusion: { in: [true, false] }
  validates :system, inclusion: { in: [true, false] }

  def display_name
    system? ? I18n.t("ban_reasons.system.#{name}") : name
  end

  def display_description
    system? ? I18n.t("ban_reasons.system_descriptions.#{name}") : description
  end

  def editable?
    !system || (system && changes.keys == ['active'])
  end

  def deletable?
    !system && !reports.exists?
  end
end
