# frozen_string_literal: true

create_table 'tenant_unsubscription_histories', force: :cascade do |t|
  t.bigint   'user_id',         null: false
  t.bigint   'tenant_id',       null: false
  t.integer  'comment_policy',  null: false
  t.integer  'topic_policy',    null: false
  t.datetime 'unsubscribed_at', null: false
  t.datetime 'created_at',      null: false
  t.datetime 'updated_at',      null: false

  t.index %w[user_id], name: 'index_tenant_unsubscription_histories_on_user_id'
  t.index %w[tenant_id unsubscribed_at], name: 'index_tenant_unsubscription_histories_on_tenant_id'
end
