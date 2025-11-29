# frozen_string_literal: true

# == Schema Information
#
# Table name: job_executions
#
#  id                                                       :bigint           not null, primary key
#  arguments                                                :json
#  attempt_number                                           :integer          default(0)
#  completed_at                                             :datetime
#  enqueued_at                                              :datetime         not null
#  error_backtrace                                          :text(65535)
#  error_class                                              :string(255)
#  error_message                                            :text(65535)
#  failed_at                                                :datetime
#  job_class                                                :string(255)      not null
#  queue_name                                               :string(255)      not null
#  started_at                                               :datetime
#  status(ジョブ状態(enqueued, running, completed, failed)) :string(255)      default("enqueued"), not null
#  created_at                                               :datetime         not null
#  updated_at                                               :datetime         not null
#  job_id                                                   :string(255)      not null
#
# Indexes
#
#  idx_job_executions_job_class_created_at         (job_class,created_at)
#  idx_job_executions_job_class_status_created_at  (job_class,status,created_at)
#  idx_job_executions_job_id                       (job_id) UNIQUE
#  idx_job_executions_status_created_at            (status,created_at)
#
FactoryBot.define do
  factory :job_execution do
    sequence(:job_id) { |n| "job_#{n}_#{SecureRandom.uuid}" }
    job_class { 'ProcessUnsubscriptionJob' }
    queue_name { 'default' }
    arguments { [1, [2, 3]] }
    status { :enqueued }
    attempt_number { 0 }
    enqueued_at { Time.current }

    trait :enqueued do
      status { :enqueued }
    end

    trait :running do
      status { :running }
      started_at { 1.minute.ago }
    end

    trait :completed do
      status { :completed }
      started_at { 5.minutes.ago }
      completed_at { 1.minute.ago }
    end

    trait :failed do
      status { :failed }
      started_at { 5.minutes.ago }
      failed_at { 1.minute.ago }
      error_class { 'StandardError' }
      error_message { 'Something went wrong' }
      error_backtrace { ['line 1', 'line 2', 'line 3'].join("\n") }
    end
  end
end
