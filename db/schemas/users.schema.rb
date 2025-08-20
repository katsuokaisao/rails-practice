create_table 'users', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.string   'nickname',   null: false
  t.string   'role',       null: false, default: 'user', comment: "(enum: 'user' | 'moderator')"
  t.datetime 'retired_at', null: true
  t.datetime 'created_at', null: false
  t.datetime 'updated_at', null: false

  t.index ['nickname'], name: 'idx_users_nickname', unique: true
end
