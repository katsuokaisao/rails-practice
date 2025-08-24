# frozen_string_literal: true

create_table 'comment_histories', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'comment_id', null: false
  t.bigint   'topic_id', null: false
  t.bigint   'author_id',        null: false
  t.integer  'version_no',       null: false
  t.text     'content',          null: false
  t.datetime 'created_at',       null: false

  t.index %w[comment_id version_no], name: 'idx_comment_histories_comment_id', unique: true
end

add_foreign_key 'comment_histories', 'comments', column: 'comment_id'
