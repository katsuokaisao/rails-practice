# frozen_string_literal: true

create_table 'topics', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'tenant_id',     null: false
  t.bigint   'author_id',     null: false
  t.string   'title',         null: false
  t.integer  'total_comment', null: false, default: 0
  t.datetime 'locked_at',     null: true
  t.datetime 'created_at',    null: false
  t.datetime 'updated_at',    null: false

  t.index %w[tenant_id created_at], name: 'idx_topics_tenant_id_created_at'
  t.index %w[author_id], name: 'idx_topics_author_id'
end

add_foreign_key 'topics', 'tenants', column: 'tenant_id'
add_foreign_key 'topics', 'users', column: 'author_id'
