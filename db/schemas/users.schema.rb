# frozen_string_literal: true

create_table 'users', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.string   'login_id',           null: false
  t.string   'encrypted_password', null: false
  t.datetime 'suspended_until',    null: true
  t.string   'time_zone',          null: false, default: 'Tokyo'
  t.datetime 'created_at',         null: false
  t.datetime 'updated_at',         null: false

  t.index ['login_id'], name: 'idx_users_login_id', unique: true
end
