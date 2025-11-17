# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnsubscriptionProcessor, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user) }
  let(:membership) { create(:tenant_membership, user: user, tenant: tenant) }
  let(:processor) { described_class.new(membership) }

  describe '#execute' do
    context '正常系' do
      it '退会履歴が作成される' do
        membership.update!(unsubscribed_at: Time.current)
        expect do
          processor.execute
        end.to change(TenantUnsubscriptionHistory, :count).by(1)
      end

      context 'コメントポリシーがdeleteの場合' do
        let(:tenant) { create(:tenant, unsubscribed_user_comment_policy: :delete) }
        let(:other_user) { create(:user) }
        let!(:topic) { create(:topic, tenant: tenant, author: other_user) }
        let!(:comment) { create(:comment, topic: topic, author: user) }

        it 'ユーザーのコメントが削除される' do
          expect do
            processor.execute
          end.to change { Comment.exists?(comment.id) }.from(true).to(false)
        end

        it 'コメント削除時にCommentHistoryも削除される' do
          comment_history_id = comment.histories.first.id

          expect do
            processor.execute
          end.to change { CommentHistory.exists?(comment_history_id) }.from(true).to(false)
        end

        it 'コメント削除時に通報も削除される' do
          report = create(:report, reportable: comment, reporter: other_user, tenant: tenant)

          expect do
            processor.execute
          end.to change { Report.exists?(report.id) }.from(true).to(false)
        end
      end

      context 'コメントポリシーがhide_contentの場合' do
        let(:tenant) { create(:tenant, unsubscribed_user_comment_policy: :hide_content) }
        let(:other_user) { create(:user) }
        let!(:topic) { create(:topic, tenant: tenant, author: other_user) }
        let!(:comment) { create(:comment, topic: topic, author: user) }

        it 'ユーザーのコメントは削除されない' do
          expect do
            processor.execute
          end.not_to(change { Comment.exists?(comment.id) })
        end
      end

      context 'トピックポリシーがlockの場合' do
        let(:tenant) { create(:tenant, unsubscribed_user_topic_policy: :lock) }
        let!(:topic) { create(:topic, tenant: tenant, author: user, locked_at: nil) }

        it 'ユーザーのトピックがロックされる' do
          processor.execute
          expect(topic.reload.locked_at).to be_present
        end
      end

      context 'トピックポリシーがdeleteの場合' do
        let(:tenant) { create(:tenant, unsubscribed_user_topic_policy: :delete) }
        let!(:topic) { create(:topic, tenant: tenant, author: user) }

        it 'ユーザーのトピックが削除される' do
          expect do
            processor.execute
          end.to change { Topic.exists?(topic.id) }.from(true).to(false)
        end

        context 'トピックにコメントがある場合' do
          let(:other_user) { create(:user) }
          let!(:comment) { create(:comment, topic: topic, author: other_user) }

          it 'トピック削除時にコメントも削除される' do
            expect do
              processor.execute
            end.to change { Comment.exists?(comment.id) }.from(true).to(false)
          end

          it 'トピック削除時にCommentHistoryも削除される' do
            comment_history_id = comment.histories.first.id

            expect do
              processor.execute
            end.to change { CommentHistory.exists?(comment_history_id) }.from(true).to(false)
          end

          it 'トピック削除時に通報も削除される' do
            report = create(:report, reportable: comment, reporter: other_user, tenant: tenant)

            expect do
              processor.execute
            end.to change { Report.exists?(report.id) }.from(true).to(false)
          end
        end
      end
    end

    context '異常系' do
      context 'membershipがnilの場合' do
        let(:processor) { described_class.new(nil) }

        it 'ActiveModel::ValidationErrorが発生する' do
          expect do
            processor.execute
          end.to raise_error(ActiveModel::ValidationError)
        end
      end
    end
  end
end
