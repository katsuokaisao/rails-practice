# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  before_perform do |job|
    job_execution = find_or_create_job_execution(job)
    job_execution.update!(
      status: :running,
      started_at: Time.current,
      attempt_number: job.executions
    )
  end

  after_perform do |job|
    job_execution = find_job_execution(job)
    job_execution&.update!(
      status: :completed,
      completed_at: Time.current
    )
  end

  rescue_from(StandardError) do |exception|
    job_execution = find_job_execution(self)
    job_execution&.update!(
      status: :failed,
      failed_at: Time.current,
      error_class: exception.class.name,
      error_message: exception.message,
      error_backtrace: exception.backtrace&.first(10)&.join("\n")
    )

    raise exception
  end

  private

  def find_or_create_job_execution(job_instance)
    JobExecution.find_or_create_by!(job_id: job_instance.job_id) do |execution|
      execution.job_class = job_instance.class.name
      execution.arguments = job_instance.arguments
      execution.queue_name = job_instance.queue_name
      execution.status = :enqueued
      execution.enqueued_at = Time.current
    end
  end

  def find_job_execution(job_instance)
    JobExecution.find_by(job_id: job_instance.job_id)
  end
end
