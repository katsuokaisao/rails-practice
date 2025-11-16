# frozen_string_literal: true

require 'rails_helper'

class TestSuccessJob < ApplicationJob
  def perform(arg1, arg2)
    arg1 + arg2
  end
end

class TestFailureJob < ApplicationJob
  def perform
    raise StandardError, 'Test error message'
  end
end

RSpec.describe ApplicationJob, type: :job do
  describe 'JobExecution追跡' do
    context '成功時' do
      it 'JobExecutionレコードが作成され、成功情報が記録される' do
        expect do
          TestSuccessJob.perform_now(1, 2)
        end.to change(JobExecution, :count).by(1)

        job_execution = JobExecution.last

        expect(job_execution.job_id).to be_present
        expect(job_execution.job_class).to eq('TestSuccessJob')
        expect(job_execution.arguments).to eq([1, 2])
        expect(job_execution.queue_name).to eq('default')

        expect(job_execution.status).to eq('completed')
        expect(job_execution.enqueued_at).to be_present
        expect(job_execution.started_at).to be_present
        expect(job_execution.completed_at).to be_present
        expect(job_execution.attempt_number).to eq(1)

        expect(job_execution.failed_at).to be_nil
        expect(job_execution.error_class).to be_nil
        expect(job_execution.error_message).to be_nil
        expect(job_execution.error_backtrace).to be_nil
      end
    end

    context '失敗時' do
      it 'JobExecutionレコードが作成され、エラー情報が記録される' do
        expect do
          TestFailureJob.perform_now
        end.to raise_error(StandardError).and change(JobExecution, :count).by(1)

        job_execution = JobExecution.last

        expect(job_execution.status).to eq('failed')
        expect(job_execution.failed_at).to be_present
        expect(job_execution.completed_at).to be_nil

        expect(job_execution.error_class).to eq('StandardError')
        expect(job_execution.error_message).to eq('Test error message')
        expect(job_execution.error_backtrace).to be_present
        expect(job_execution.error_backtrace).to include('application_job_spec.rb')
      end

      it '例外が再raiseされる' do
        expect do
          TestFailureJob.perform_now
        end.to raise_error(StandardError, 'Test error message')
      end
    end
  end
end
