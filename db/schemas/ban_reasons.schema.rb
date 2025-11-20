# frozen_string_literal: true

create_table 'ban_reasons', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'tenant_id',   null: false
  t.string   'name',        null: false
  t.text     'description', null: true
  t.boolean  'active',      null: false, default: true
  t.boolean  'system',      null: false, default: false, comment: 'システム基本理由かどうか'
  t.datetime 'created_at',  null: false
  t.datetime 'updated_at',  null: false

  t.index %w[tenant_id active], name: 'idx_ban_reasons_tenant_id_active'
  t.index %w[tenant_id name], name: 'uniq_ban_reasons_tenant_name', unique: true
end

add_foreign_key 'ban_reasons', 'tenants', column: 'tenant_id'
