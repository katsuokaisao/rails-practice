# frozen_string_literal: true

create_table :tenant_memberships, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'tenant_id',    null: false
  t.bigint   'user_id',      null: false
  t.string   'display_name', null: false
  t.datetime 'created_at',   null: false
  t.datetime 'updated_at',   null: false

  t.index %i[tenant_id user_id], unique: true, name: 'idx_tenant_memberships_tenant_user'
  t.index %i[tenant_id display_name], unique: true, name: 'idx_tenant_memberships_tenant_display_name'
  t.index ['user_id'], name: 'idx_tenant_memberships_user_id'
end

add_foreign_key 'tenant_memberships', 'tenants', column: 'tenant_id'
add_foreign_key 'tenant_memberships', 'users', column: 'user_id'
