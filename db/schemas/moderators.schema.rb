# frozen_string_literal: true

create_table 'moderators', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'tenant_id',          null: false
  t.string   'login_id',           null: false
  t.string   'encrypted_password', null: false
  t.string   'time_zone',          null: false, default: 'Tokyo'
  t.datetime 'created_at',         null: false
  t.datetime 'updated_at',         null: false

  t.index ['tenant_id'], name: 'idx_moderators_tenant_id'
  t.index ['login_id'],  name: 'idx_moderators_login_id', unique: true
end
