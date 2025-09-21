# frozen_string_literal: true

create_table 'decisions', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'report_id',        null: false
  t.string   'decision_type',    null: false, comment: "(enum: 'reject' | 'hide_comment' | 'suspend_user')"
  t.bigint   'decided_by',       null: false
  t.text     'note',             null: true
  t.datetime 'suspended_until', null: true
  t.datetime 'created_at', null: false

  t.index ['report_id'],                name: 'idx_decisions_report_id', unique: true
  t.index ['decided_by'],               name: 'idx_decisions_decided_by'
  t.index %w[created_at report_id], name: 'idx_decisions_created_at_report_id'
end

add_foreign_key 'decisions', 'reports',    column: 'report_id'
add_foreign_key 'decisions', 'moderators', column: 'decided_by'
