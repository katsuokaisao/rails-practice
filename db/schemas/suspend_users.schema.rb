# frozen_string_literal: true

create_table 'suspend_users', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'user_id',         null: false
  t.datetime 'suspended_until', null: false
  t.datetime 'created_at',      null: false
  t.datetime 'updated_at',      null: false

  t.index ['user_id'], name: 'idx_suspend_users_user_id', unique: true
end
