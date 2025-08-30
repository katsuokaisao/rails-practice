# frozen_string_literal: true

create_table 'users', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.string   'nickname',           null: false
  t.string   'encrypted_password', null: false
  t.string   'time_zone',          null: false, default: 'Tokyo'
  t.datetime 'retired_at',         null: true
  t.datetime 'created_at',         null: false
  t.datetime 'updated_at',         null: false

  t.index ['nickname'], name: 'idx_users_nickname', unique: true
end
