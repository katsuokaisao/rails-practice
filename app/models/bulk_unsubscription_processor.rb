# frozen_string_literal: true

class BulkUnsubscriptionProcessor
  include ActiveModel::Model

  attr_accessor :user, :tenant_ids

  validates :user, presence: true
  validates :tenant_ids, presence: true
  validate :at_least_one_valid_membership

  def initialize(user, tenant_ids)
    @user = user
    @tenant_ids = Array(tenant_ids).map(&:to_i)
  end

  def execute
    raise ActiveModel::ValidationError, self unless valid?

    tenant_ids.each do |tenant_id|
      process_single_unsubscription(tenant_id)
    end
  end

  private

  def process_single_unsubscription(tenant_id)
    membership = user.tenant_memberships.active.find_by(tenant_id: tenant_id)
    return unless membership

    processor = UnsubscriptionProcessor.new(membership)
    processor.execute
  end

  def at_least_one_valid_membership
    return if user.blank? || tenant_ids.blank?

    active_count = user.tenant_memberships.active.where(tenant_id: tenant_ids).count
    return unless active_count.zero?

    errors.add(:base, I18n.t('errors.messages.no_active_memberships'))
  end
end
