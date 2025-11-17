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
FactoryBot.define do
  factory :tenant_unsubscription_history do
    association :user
    association :tenant
    comment_policy { 'hide_content' }
    topic_policy { 'lock' }
    unsubscribed_at { Time.current }
  end
end
