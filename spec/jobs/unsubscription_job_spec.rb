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
      expect do
        described_class.perform_now(user.id, [first_tenant.id])
      end.to change(TenantUnsubscriptionHistory, :count).by(1)

      history = TenantUnsubscriptionHistory.find_by(user: user, tenant: first_tenant)
      expect(history).to be_present
      expect(history.comment_policy).to eq(first_tenant.unsubscribed_user_comment_policy)
      expect(history.topic_policy).to eq(first_tenant.unsubscribed_user_topic_policy)
    end

    it '不正なパラメータの場合に退会処理が失敗する' do
      expect do
        described_class.perform_now(999, [first_tenant.id])
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
