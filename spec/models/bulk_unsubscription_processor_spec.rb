# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkUnsubscriptionProcessor, type: :model do
  let(:user) { create(:user) }
  let(:first_tenant) { create(:tenant) }
  let(:second_tenant) { create(:tenant) }
  let!(:first_membership) { create(:tenant_membership, user: user, tenant: first_tenant) }
  let!(:second_membership) { create(:tenant_membership, user: user, tenant: second_tenant) }

  describe '#execute' do
    context '正常系' do
      let(:processor) { described_class.new(user, [first_tenant.id, second_tenant.id]) }

      it '複数のテナントから退会できる' do
        processor.execute

        expect(first_membership.reload.unsubscribed_at).to be_present
        expect(second_membership.reload.unsubscribed_at).to be_present
      end

      it '退会履歴が複数作成される' do
        expect do
          processor.execute
        end.to change(TenantUnsubscriptionHistory, :count).by(2)
      end
    end

    context '異常系' do
      context 'アクティブなメンバーシップが1つもない場合' do
        let(:processor) { described_class.new(user, [999]) }

        it 'バリデーションエラーになる' do
          expect(processor).to be_invalid
          expect(processor.errors[:base]).to be_present
        end

        it 'executeでActiveModel::ValidationErrorが発生する' do
          expect do
            processor.execute
          end.to raise_error(ActiveModel::ValidationError)
        end
      end
    end

    context '冪等性' do
      let(:processor) { described_class.new(user, [first_tenant.id, second_tenant.id]) }

      it '既に退会済みのテナントはスキップされる' do
        processor.execute
        processor2 = described_class.new(user, [first_tenant.id, second_tenant.id])

        expect(processor2).to be_invalid
        expect do
          processor2.execute
        end.to raise_error(ActiveModel::ValidationError)
      end

      it '一部が退会済みの場合、アクティブなメンバーシップのみ処理される' do
        processor1 = described_class.new(user, [first_tenant.id])
        processor1.execute

        processor2 = described_class.new(user, [first_tenant.id, second_tenant.id])

        expect do
          processor2.execute
        end.to change(TenantUnsubscriptionHistory, :count).by(1)

        expect(second_membership.reload.unsubscribed_at).to be_present
      end
    end
  end
end
