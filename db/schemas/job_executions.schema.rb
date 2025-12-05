# frozen_string_literal: true

create_table 'job_executions', force: :cascade do |t|
  t.string 'job_id', null: false
  t.string 'job_class', null: false
  t.string 'queue_name', null: false
  t.json 'arguments'

  t.string 'status', null: false, default: 'enqueued', comment: 'ジョブ状態(enqueued, running, completed, failed)'
  t.integer 'attempt_number', default: 0

  t.datetime 'enqueued_at', null: false
  t.datetime 'started_at'
  t.datetime 'completed_at'
  t.datetime 'failed_at'

  t.string 'error_class'
  t.text 'error_message'
  t.text 'error_backtrace'

  t.datetime 'created_at', null: false
  t.datetime 'updated_at', null: false

  t.index ['job_id'], name: 'idx_job_executions_job_id', unique: true
  t.index %w[job_class created_at], name: 'idx_job_executions_job_class_created_at'
  t.index %w[job_class status created_at], name: 'idx_job_executions_job_class_status_created_at'
  t.index %w[status created_at], name: 'idx_job_executions_status_created_at'
end
