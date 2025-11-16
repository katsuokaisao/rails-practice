# frozen_string_literal: true

class UnsubscriptionJob < ApplicationJob
  queue_as :default

  def perform(user_id, tenant_ids)
    user = User.find(user_id)
    processor = BulkUnsubscriptionProcessor.new(user, tenant_ids)
    processor.execute
  end
end
