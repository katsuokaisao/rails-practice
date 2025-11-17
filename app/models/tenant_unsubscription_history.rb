# frozen_string_literal: true

# == Schema Information
#
# Table name: tenant_unsubscription_histories
#
#  id              :bigint           not null, primary key
#  comment_policy  :string(255)      not null
#  topic_policy    :string(255)      not null
#  unsubscribed_at :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  tenant_id       :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_tenant_unsubscription_histories_on_tenant_id  (tenant_id,unsubscribed_at)
#  index_tenant_unsubscription_histories_on_user_id    (user_id)
#
class TenantUnsubscriptionHistory < ApplicationRecord
  belongs_to :user
  belongs_to :tenant

  validates :comment_policy, presence: true
  validates :topic_policy, presence: true
  validates :unsubscribed_at, presence: true
end
