# frozen_string_literal: true

create_table 'topics', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'author_id',     null: false
  t.string   'title',         null: false
  t.integer  'total_comment', null: false, default: 0
  t.datetime 'created_at',    null: false
  t.datetime 'updated_at',    null: false

  t.index ['author_id'],  name: 'idx_topics_author_id'
  t.index ['created_at'], name: 'idx_topics_created_at'
end

add_foreign_key 'topics', 'users', column: 'author_id'
