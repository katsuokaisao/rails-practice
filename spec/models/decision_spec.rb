# frozen_string_literal: true

# == Schema Information
#
# Table name: decisions
#
#  id                                                                :bigint           not null, primary key
#  decided_by                                                        :bigint           not null
#  decision_type((enum: 'reject' | 'hide_comment' | 'suspend_user')) :string(255)      not null
#  note                                                              :text(65535)
#  suspended_until                                                   :datetime
#  created_at                                                        :datetime         not null
#  report_id                                                         :bigint           not null
#  tenant_id                                                         :bigint           not null
#
# Indexes
#
#  idx_decisions_decided_by            (decided_by)
#  idx_decisions_report_id             (report_id) UNIQUE
#  idx_decisions_tenant_id_created_at  (tenant_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (decided_by => moderators.id)
#  fk_rails_...  (report_id => reports.id)
#  fk_rails_...  (tenant_id => tenants.id)
#
require 'rails_helper'

RSpec.describe Decision, type: :model do
  describe '#save!' do
    let(:tenant) { create(:tenant) }
    let(:moderator) { create(:moderator, tenant: tenant) }

    context '通報を却下する場合' do
      context 'ユーザ通報の場合' do
        let(:report) { create(:report, :for_user, tenant: tenant) }
        let(:decision) do
          build(:decision, tenant: tenant, report: report, decider: moderator, decision_type: 'reject')
        end

        it 'レコードが保存され、ユーザーが一時停止されていないこと' do
          expect do
            decision.save!
          end.to change(described_class, :count).by(1)

          expect(decision).to be_persisted
          expect(report.reload.reportable.suspended?(tenant)).to be false
        end

        context '類似の通報がある場合' do
          let!(:similar_report) { create(:report, :for_user, tenant: tenant, reportable: report.reportable) }

          it '類似の通報に同じ審査結果が適用されないこと' do
            expect do
              decision.save!
            end.to change(described_class, :count).by(1)

            similar_decision = similar_report.reload.decision
            expect(similar_decision).to be_nil
          end
        end
      end

      context 'コメント通報の場合' do
        let(:report) { create(:report, :for_comment, tenant: tenant) }
        let(:decision) do
          build(:decision, tenant: tenant, report: report, decider: moderator, decision_type: 'reject')
        end

        it 'レコードが保存され、コメントが非表示になっていないこと' do
          expect do
            decision.save!
          end.to change(described_class, :count).by(1)

          expect(decision).to be_persisted
          expect(report.reload.reportable).not_to be_hidden
        end

        context '類似の通報がある場合' do
          let!(:similar_report) { create(:report, :for_comment, tenant: tenant, reportable: report.reportable) }

          it '類似の通報に同じ審査結果が適用されないこと' do
            expect do
              decision.save!
            end.to change(described_class, :count).by(1)

            similar_decision = similar_report.reload.decision
            expect(similar_decision).to be_nil
          end
        end
      end
    end

    context 'コメントを非表示にする場合' do
      let(:report) { create(:report, :for_comment, tenant: tenant) }
      let(:decision) do
        build(:decision, tenant: tenant, report: report, decider: moderator, decision_type: 'hide_comment')
      end

      it 'レコードが保存され、コメントが非表示になること' do
        comment = report.reportable
        expect(comment).not_to be_hidden

        expect do
          decision.save!
        end.to change(described_class, :count).by(1)

        expect(decision).to be_persisted
        expect(comment.reload).to be_hidden
        expect(comment.hidden_cause_decision).to eq(decision)
      end

      context '類似の通報がある場合' do
        let!(:similar_report) { create(:report, :for_comment, tenant: tenant, reportable: report.reportable) }

        it '類似の通報に同じ決定が適用されること' do
          expect do
            decision.save!
          end.to change(described_class, :count).by(2)

          similar_decision = similar_report.reload.decision
          expect(similar_decision).to be_present
          expect(similar_decision.decision_type).to eq('hide_comment')
          expect(similar_decision.decider).to eq(moderator)
        end
      end
    end

    context 'ユーザーを一時停止する場合' do
      let(:report) { create(:report, :for_user, tenant: tenant) }
      let(:decision) do
        build(:decision,
              tenant: tenant,
              report: report,
              decider: moderator,
              decision_type: 'suspend_user',
              suspended_until: nil)
      end

      it 'レコードが保存され、ユーザーが一時停止されること' do
        suspended_until = 7.days.from_now
        decision.suspended_until = suspended_until

        user = report.reportable
        expect(user.suspended?(tenant)).to be false

        expect do
          decision.save!
        end.to change(described_class, :count).by(1)
          .and(change { user.reload.suspended?(tenant) }.from(false).to(true))

        expect(decision).to be_persisted
        expect(user.reload.suspended?(tenant)).to be true
        membership = user.tenant_memberships.find_by(tenant: tenant)
        expect(membership.suspended_until).to be_within(1.second).of(suspended_until)
      end

      context '類似の通報がある場合' do
        let!(:similar_report) { create(:report, :for_user, tenant: tenant, reportable: report.reportable) }

        it '類似の通報に同じ決定が適用されること' do
          suspended_until = 7.days.from_now
          decision.suspended_until = suspended_until
          expect do
            decision.save!
          end.to change(described_class, :count).by(2)

          similar_decision = similar_report.reload.decision
          expect(similar_decision).to be_present
          expect(similar_decision.decision_type).to eq('suspend_user')
          expect(similar_decision.decider).to eq(moderator)
          expect(similar_decision.suspended_until).to be_within(1.second).of(suspended_until)
        end
      end
    end

    context 'トランザクション' do
      let(:report) { create(:report, :for_comment, tenant: tenant) }
      let(:decision) do
        build(:decision, tenant: tenant, report: report, decider: moderator, decision_type: 'hide_comment')
      end

      context 'save! が失敗した場合' do
        before do
          allow(decision).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(decision))
        end

        it '全体がロールバックされること' do
          comment = report.reportable
          expect(comment).not_to be_hidden

          expect do
            expect { decision.save! }.to raise_error(ActiveRecord::RecordInvalid)
          end.to change(described_class, :count).by(0)

          expect(comment.reload).not_to be_hidden
        end
      end

      context 'apply_decision! が失敗した場合' do
        before do
          allow(decision).to receive(:apply_decision!).and_raise(StandardError.new('効果適用エラー'))
        end

        it '全体がロールバックされること' do
          comment = report.reportable
          expect(comment).not_to be_hidden

          expect do
            expect { decision.save! }.to raise_error(StandardError, '効果適用エラー')
          end.to change(described_class, :count).by(0)

          expect(comment.reload).not_to be_hidden
        end
      end

      context 'apply_decision_for_similar_reports! が失敗した場合' do
        let!(:similar_report) { create(:report, :for_comment, tenant: tenant, reportable: report.reportable) }

        before do
          allow(decision).to receive(:apply_decision_for_similar_reports!).and_raise(StandardError.new('伝播エラー'))
        end

        it 'トランザクション内の処理はコミットされないこと' do
          comment = report.reportable
          expect(comment).not_to be_hidden

          expect do
            expect { decision.save! }.to raise_error(StandardError, '伝播エラー')
          end.to change(described_class, :count).by(0)

          expect(comment.reload).not_to be_hidden
          expect(comment.hidden_cause_decision).to be_nil
        end
      end
    end
  end
end
