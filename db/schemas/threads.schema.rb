create_table 'forum_threads', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'author_id',  null: false
  t.string   'title',      null: false
  t.datetime 'created_at', null: false
  t.datetime 'updated_at', null: false

  t.index ['created_at'], name: 'idx_forum_threads_created_at'
  t.index ['author_id'],  name: 'idx_forum_threads_author_id'
end

add_foreign_key 'forum_threads', 'users', column: 'author_id'
