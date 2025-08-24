# frozen_string_literal: true

create_table 'moderators', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.string   'nickname',           null: false
  t.string   'encrypted_password', null: false
  t.datetime 'retired_at',         null: true
  t.datetime 'created_at',         null: false
  t.datetime 'updated_at',         null: false

  t.index ['nickname'], name: 'idx_moderators_nickname', unique: true
end
