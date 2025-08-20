create_table 'posts', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'forum_thread_id',    null: false
  t.bigint   'author_id',          null: false
  t.text     'content',            null: false
  t.integer  'current_version_no', null: false
  t.boolean  'hidden',             null: false, default: false
  t.string   'hidden_reason_type', null: false
  t.text     'hidden_reason_text', null: false
  t.datetime 'created_at',         null: false
  t.datetime 'updated_at',         null: false

  t.index ['forum_thread_id'], name: 'idx_posts_forum_thread_id'
  t.index ['author_id'],       name: 'idx_posts_author_id'
end

add_foreign_key 'posts', 'forum_threads', column: 'forum_thread_id'
add_foreign_key 'posts', 'users',         column: 'author_id'
