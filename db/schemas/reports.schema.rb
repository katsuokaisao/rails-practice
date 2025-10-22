# frozen_string_literal: true

create_table 'reports', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.string   'reportable_type',   null: false, comment: "(enum: 'Comment' | 'User')"
  t.bigint   'reportable_id',     null: true
  t.bigint   'reporter_id',       null: false
  t.string   'reason_type',       null: false
  t.text     'reason_text',       null: false
  t.datetime 'created_at',        null: false
  t.datetime 'updated_at',        null: false

  t.index %w[reportable_type created_at], name: 'idx_reports_reportable_type_created_at'
  t.index %w[reportable_type reportable_id], name: 'idx_reports_reportable_type_reportable_id'
  t.index ['reporter_id'], name: 'idx_reports_reporter_id'
end
