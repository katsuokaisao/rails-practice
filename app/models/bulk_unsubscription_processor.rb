# frozen_string_literal: true

class BulkUnsubscriptionProcessor
  include ActiveModel::Model

  attr_accessor :user, :tenant_ids

  validates :user, presence: true
  validates :tenant_ids, presence: true

  def initialize(user, tenant_ids)
    @user = user
    @tenant_ids = Array(tenant_ids).map(&:to_i)
  end

  def execute
    raise ActiveModel::ValidationError, self unless valid?

    ActiveRecord::Base.transaction do
      tenant_ids.each do |tenant_id|
        process_single_unsubscription(tenant_id)
      end
    end
  end

  private

  def process_single_unsubscription(tenant_id)
    membership = user.tenant_memberships
                     .find_by(tenant_id: tenant_id)
    return unless membership

    processor = UnsubscriptionProcessor.new(membership)
    processor.execute
  end
end
