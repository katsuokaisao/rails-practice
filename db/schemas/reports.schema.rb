# frozen_string_literal: true

create_table 'reports', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.string   'target_type',       null: false, comment: "(enum: 'comment' | 'user')"
  t.bigint   'target_user_id',    null: true
  t.bigint   'target_comment_id', null: true
  t.bigint   'reporter_id',       null: false
  t.string   'reason_type',       null: false
  t.text     'reason_text',       null: false
  t.datetime 'created_at',        null: false
  t.datetime 'updated_at',        null: false

  t.index %w[target_type created_at], name: 'idx_reports_target_type_created_at'
  t.index ['target_user_id'], name: 'idx_reports_target_user_id'
  t.index ['target_comment_id'], name: 'idx_reports_target_comment_id'
  t.index ['reporter_id'], name: 'idx_reports_reporter_id'
end

add_foreign_key 'reports', 'users', column: 'target_user_id'
add_foreign_key 'reports', 'comments', column: 'target_comment_id'
add_foreign_key 'reports', 'users', column: 'reporter_id'
