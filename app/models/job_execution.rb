# frozen_string_literal: true

# == Schema Information
#
# Table name: job_executions
#
#  id              :bigint           not null, primary key
#  arguments       :json
#  attempt_number  :integer          default(0)
#  completed_at    :datetime
#  enqueued_at     :datetime         not null
#  error_backtrace :text(65535)
#  error_class     :string(255)
#  error_message   :text(65535)
#  failed_at       :datetime
#  job_class       :string(255)      not null
#  queue_name      :string(255)      not null
#  started_at      :datetime
#  status          :string(255)      default("enqueued"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  job_id          :string(255)      not null
#
# Indexes
#
#  idx_job_executions_job_class_created_at         (job_class,created_at)
#  idx_job_executions_job_class_status_created_at  (job_class,status,created_at)
#  idx_job_executions_job_id                       (job_id) UNIQUE
#  idx_job_executions_status_created_at            (status,created_at)
#
class JobExecution < ApplicationRecord
  enum :status, {
    enqueued: 'enqueued',
    running: 'running',
    completed: 'completed',
    failed: 'failed'
  }, validate: true

  validates :job_id, uniqueness: true

  def execution_duration
    return nil unless started_at && (completed_at || failed_at)

    (completed_at || failed_at) - started_at
  end

  def queue_duration
    return nil unless enqueued_at && started_at

    started_at - enqueued_at
  end
end
