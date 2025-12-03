# frozen_string_literal: true

create_table 'reports', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'tenant_id',         null: false
  t.string   'reportable_type',   null: false, comment: "(enum: 'Comment' | 'User')"
  t.bigint   'reportable_id',     null: true
  t.bigint   'reporter_id',       null: false
  t.bigint   'ban_reason_id',     null: false
  t.text     'reason_text',       null: false
  t.datetime 'created_at',        null: false
  t.datetime 'updated_at',        null: false

  t.index %w[tenant_id reportable_type created_at], name: 'idx_reports_reportable_type_created_at'
  t.index %w[tenant_id reportable_type reportable_id], name: 'idx_reports_reportable_type_reportable_id'
  t.index %w[tenant_id reporter_id], name: 'idx_reports_reporter_id'
  t.index ['ban_reason_id'], name: 'idx_reports_ban_reason_id'
end

add_foreign_key 'reports', 'tenants', column: 'tenant_id'
add_foreign_key 'reports', 'ban_reasons', column: 'ban_reason_id'
