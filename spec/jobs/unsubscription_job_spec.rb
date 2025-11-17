# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnsubscriptionJob, type: :job do
  let(:user) { create(:user) }
  let(:first_tenant) { create(:tenant) }
  let(:second_tenant) { create(:tenant) }
  let!(:first_membership) { create(:tenant_membership, user: user, tenant: first_tenant) }
  let!(:second_membership) { create(:tenant_membership, user: user, tenant: second_tenant) }

  describe '#perform' do
    it '正しいパラメータの場合に退会処理に成功する' do
      described_class.perform_now(user.id, [first_tenant.id])

      job_execution = JobExecution.last
      expect(job_execution.status).to eq('completed')
      expect(job_execution.completed_at).to be_present
    end

    it '不正なパラメータの場合に退会処理が失敗する' do
      expect do
        described_class.perform_now(999, [first_tenant.id])
      end.to raise_error(ActiveRecord::RecordNotFound)

      job_execution = JobExecution.last
      expect(job_execution.status).to eq('failed')
      expect(job_execution.failed_at).to be_present
      expect(job_execution.error_class).to eq('ActiveRecord::RecordNotFound')
    end
  end
end
