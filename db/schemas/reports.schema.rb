# frozen_string_literal: true

create_table 'reports', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.string   'target_type',       null: false, comment: "(enum: 'Comment' | 'User')"
  t.bigint   'target_id',         null: true
  t.bigint   'reporter_id',       null: false
  t.string   'reason_type',       null: false
  t.text     'reason_text',       null: false
  t.datetime 'created_at',        null: false
  t.datetime 'updated_at',        null: false

  t.index %w[target_type created_at], name: 'idx_reports_target_type_created_at'
  t.index %w[target_type target_id], name: 'idx_reports_target'
  t.index ['reporter_id'], name: 'idx_reports_reporter_id'
end
