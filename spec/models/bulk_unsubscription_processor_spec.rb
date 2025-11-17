# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkUnsubscriptionProcessor, type: :model do
  let(:user) { create(:user) }
  let(:first_tenant) { create(:tenant) }
  let(:second_tenant) { create(:tenant) }
  let!(:first_membership) { create(:tenant_membership, :unsubscribed, user: user, tenant: first_tenant) }
  let!(:second_membership) { create(:tenant_membership, :unsubscribed, user: user, tenant: second_tenant) }

  describe '#execute' do
    context '正常系' do
      context '単一のテナントから退会できる' do
        let(:processor) { described_class.new(user, [first_tenant.id]) }

        it '正しいテナントの退会履歴が作成される' do
          expect do
            processor.execute
          end.to change(TenantUnsubscriptionHistory, :count).by(1)

          history = TenantUnsubscriptionHistory.find_by(user: user, tenant: first_tenant)
          expect(history.comment_policy).to eq(first_tenant.unsubscribed_user_comment_policy)
          expect(history.topic_policy).to eq(first_tenant.unsubscribed_user_topic_policy)
        end
      end

      context '複数のテナントから退会できる' do
        let(:processor) { described_class.new(user, [first_tenant.id, second_tenant.id]) }

        it '各テナントの退会履歴が作成される' do
          expect do
            processor.execute
          end.to change(TenantUnsubscriptionHistory, :count).by(2)

          expect(TenantUnsubscriptionHistory.where(user: user, tenant: first_tenant).count).to eq(1)
          expect(TenantUnsubscriptionHistory.where(user: user, tenant: second_tenant).count).to eq(1)
        end
      end
    end

    context '異常系' do
      context '不正なuser_idが指定された場合' do
        it 'ジョブ実行履歴がfailedになる' do
          expect do
            UnsubscriptionJob.perform_now(999_999, [first_tenant.id])
          end.to raise_error(ActiveRecord::RecordNotFound)

          job_execution = JobExecution.find_by(job_class: 'UnsubscriptionJob')
          expect(job_execution).to be_present
          expect(job_execution.status).to eq('failed')
          expect(job_execution.error_class).to eq('ActiveRecord::RecordNotFound')
        end
      end

      context '不正なtenant_idが指定された場合' do
        let(:processor) { described_class.new(user, [999_999]) }

        it 'エラーが発生せず、処理がスキップされる' do
          expect do
            processor.execute
          end.not_to change(TenantUnsubscriptionHistory, :count)
        end
      end
    end
  end
end
