create_table 'post_histories', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'post_id',          null: false
  t.bigint   'forum_thread_id',  null: false
  t.bigint   'author_id',        null: false
  t.integer  'version_no',       null: false
  t.text     'content',          null: false
  t.datetime 'created_at',       null: false

  t.index %w[post_id version_no], name: 'idx_post_histories_post_id', unique: true
end

add_foreign_key 'post_histories', 'posts', column: 'post_id'
