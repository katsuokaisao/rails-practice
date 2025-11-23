# frozen_string_literal: true

# == Schema Information
#
# Table name: tenants
#
#  id                               :bigint           not null, primary key
#  description                      :text(65535)      not null
#  name                             :string(255)      not null
#  policy_application_status        :string(255)      default("idle"), not null
#  slug                             :string(255)      not null
#  unsubscribed_user_comment_policy :string(255)      not null
#  unsubscribed_user_topic_policy   :string(255)      not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#
# Indexes
#
#  idx_tenants_slug  (slug) UNIQUE
#
require 'rails_helper'

RSpec.describe Tenant, type: :model do
  include ActiveJob::TestHelper

  describe '#apply_topic_policy' do
    let(:tenant) { create(:tenant, unsubscribed_user_topic_policy: :keep_visible) }
    let(:user) { create(:user) }
    let!(:membership) { create(:tenant_membership, tenant: tenant, user: user, unsubscribed_at: Time.current) }
    let!(:topic) { create(:topic, tenant: tenant, author: user) }

    context 'keep_visible → lockに変更した場合' do
      it '退会済みユーザーのトピックがロックされる' do
        perform_enqueued_jobs do
          tenant.update!(unsubscribed_user_topic_policy: :lock)
        end

        expect(topic.reload.locked?).to be true
      end

      it 'すでにロックされているトピックは変更されない' do
        topic.update!(locked_at: 1.day.ago)
        original_locked_at = topic.locked_at

        perform_enqueued_jobs do
          tenant.update!(unsubscribed_user_topic_policy: :lock)
        end

        expect(topic.reload.locked_at).to eq(original_locked_at)
      end
    end

    context 'lock → keep_visibleに変更した場合' do
      let(:tenant) { create(:tenant, unsubscribed_user_topic_policy: :lock) }
      let!(:topic) { create(:topic, tenant: tenant, author: user, locked_at: Time.current) }

      it '退会済みユーザーのロックされたトピックがアンロックされる' do
        perform_enqueued_jobs do
          tenant.update!(unsubscribed_user_topic_policy: :keep_visible)
        end

        expect(topic.reload.locked?).to be false
      end
    end

    context 'keep_visible → deleteに変更した場合' do
      it '退会済みユーザーのトピックが削除される' do
        expect do
          perform_enqueued_jobs do
            tenant.update!(unsubscribed_user_topic_policy: :delete)
          end
        end.to change { Topic.exists?(topic.id) }.from(true).to(false)
      end

      context 'トピックにコメントがある場合' do
        let(:other_user) { create(:user) }
        let!(:comment) { create(:comment, topic: topic, author: other_user) }

        it 'トピック削除時にコメントも削除される' do
          expect do
            perform_enqueued_jobs do
              tenant.update!(unsubscribed_user_topic_policy: :delete)
            end
          end.to change { Comment.exists?(comment.id) }.from(true).to(false)
        end

        it 'トピック削除時にCommentHistoryも削除される' do
          comment_history_id = comment.histories.first.id

          expect do
            perform_enqueued_jobs do
              tenant.update!(unsubscribed_user_topic_policy: :delete)
            end
          end.to change { CommentHistory.exists?(comment_history_id) }.from(true).to(false)
        end

        context 'コメントに通報がある場合' do
          let!(:report) { create(:report, reportable: comment, reporter: other_user, tenant: tenant) }

          it 'トピック削除時にReportも削除される' do
            expect do
              perform_enqueued_jobs do
                tenant.update!(unsubscribed_user_topic_policy: :delete)
              end
            end.to change { Report.exists?(report.id) }.from(true).to(false)
          end
        end
      end
    end

    context '退会済みユーザーがいない場合' do
      before { membership.update!(unsubscribed_at: nil) }

      it 'ポリシー変更しても何も起こらない' do
        expect do
          perform_enqueued_jobs do
            tenant.update!(unsubscribed_user_topic_policy: :delete)
          end
        end.not_to(change(Topic, :count))
      end
    end
  end

  describe '#apply_comment_policy' do
    let(:tenant) { create(:tenant, unsubscribed_user_comment_policy: :keep_visible) }
    let(:user) { create(:user) }
    let!(:membership) { create(:tenant_membership, tenant: tenant, user: user, unsubscribed_at: Time.current) }
    let(:other_user) { create(:user) }
    let!(:topic) { create(:topic, tenant: tenant, author: other_user) }
    let!(:comment) { create(:comment, topic: topic, author: user) }

    context 'keep_visible → deleteに変更した場合' do
      it '退会済みユーザーのコメントが削除される' do
        expect do
          perform_enqueued_jobs do
            tenant.update!(unsubscribed_user_comment_policy: :delete)
          end
        end.to change { Comment.exists?(comment.id) }.from(true).to(false)
      end

      it 'コメント削除時にCommentHistoryも削除される' do
        comment_history_id = comment.histories.first.id

        expect do
          perform_enqueued_jobs do
            tenant.update!(unsubscribed_user_comment_policy: :delete)
          end
        end.to change { CommentHistory.exists?(comment_history_id) }.from(true).to(false)
      end

      context 'コメントに通報がある場合' do
        let!(:report) { create(:report, reportable: comment, reporter: other_user, tenant: tenant) }

        it 'コメント削除時にReportも削除される' do
          expect do
            perform_enqueued_jobs do
              tenant.update!(unsubscribed_user_comment_policy: :delete)
            end
          end.to change { Report.exists?(report.id) }.from(true).to(false)
        end
      end

      context '大量のコメントがある場合（バッチ処理のテスト）' do
        let!(:comments) do
          # 1500件のコメントを作成（1000件ずつのバッチ処理を確認）
          1500.times.map do
            create(:comment, topic: topic, author: user)
          end
        end

        it '全てのコメントが削除される' do
          initial_count = Comment.where(author: user).count
          expect(initial_count).to eq(1501) # 元のcomment + 1500件

          expect do
            perform_enqueued_jobs do
              tenant.update!(unsubscribed_user_comment_policy: :delete)
            end
          end.to change { Comment.where(author: user).count }.from(1501).to(0)
        end
      end
    end

    context 'keep_visible → hide_contentに変更した場合' do
      it 'ポリシー変更しても削除処理は実行されない' do
        expect do
          perform_enqueued_jobs do
            tenant.update!(unsubscribed_user_comment_policy: :hide_content)
          end
        end.not_to(change(Comment, :count))

        expect(Comment.exists?(comment.id)).to be true
      end
    end

    context '退会済みユーザーがいない場合' do
      before { membership.update!(unsubscribed_at: nil) }

      it 'ポリシー変更しても何も起こらない' do
        expect do
          perform_enqueued_jobs do
            tenant.update!(unsubscribed_user_comment_policy: :delete)
          end
        end.not_to(change(Comment, :count))
      end
    end
  end
end
