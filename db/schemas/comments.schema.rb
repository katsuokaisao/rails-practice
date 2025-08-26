# frozen_string_literal: true

create_table 'comments', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'topic_id', null: false
  t.bigint   'author_id',          null: false
  t.text     'content',            null: false
  t.integer  'current_version_no', null: false
  t.boolean  'hidden',             null: false, default: false
  t.string   'hidden_reason_type', null: true
  t.text     'hidden_reason_text', null: true
  t.datetime 'created_at',         null: false
  t.datetime 'updated_at',         null: false

  t.index ['topic_id'], name: 'idx_comments_topic_id'
  t.index ['author_id'], name: 'idx_comments_author_id'
end

add_foreign_key 'comments', 'topics', column: 'topic_id'
add_foreign_key 'comments', 'users', column: 'author_id'
