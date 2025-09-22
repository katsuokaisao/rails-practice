# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Comments', type: :request do
  describe 'PATCH /topics/:topic_id/comments/:id' do
    let(:user) { create(:user) }
    let(:topic) { create(:topic, author: user) }
    let(:comment) { create(:comment, topic: topic, author: user, content: '元のコメント内容') }

    context '楽観的ロックが発生した場合' do
      it '409 Conflictが返され、適切なエラーメッセージが表示されること' do
        login_as(user)

        original_lock_version   = comment.lock_version
        original_version_no     = comment.current_version_no
        original_histories_cnt  = comment.histories.count

        # PATCH #1: 「セッション2」が先に保存して lock_version を進める
        patch topic_comment_path(topic, comment), params: {
          comment: { content: '別セッションでの更新', lock_version: original_lock_version }
        }
        expect(response).to have_http_status(:found)
        expect(comment.reload.lock_version).to eq(original_lock_version + 1)
        expect(comment.content).to eq('別セッションでの更新')

        # PATCH #2: 「セッション1」は古い lock_version のまま送ってしまう
        expect do
          patch topic_comment_path(topic, comment), params: {
            comment: { content: '元のセッションでの更新', lock_version: original_lock_version }
          }
        end.not_to(change { comment.reload.attributes.slice('content', 'lock_version', 'current_version_no') })

        expect(response).to have_http_status(:conflict)
        expect(response.body).to include(I18n.t('flash.actions.stale_object_error.alert'))
        expect(response.body).to include('元のセッションでの更新') # 入力していた古い値
        expect(response.body).to include('別セッションでの更新') # DBの最新値
        expect(comment.histories.count).to eq(original_histories_cnt + 1)
        expect(comment.current_version_no).to eq(original_version_no + 1)
      end
    end
  end
end
