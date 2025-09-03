# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Decisions', type: :request do
  describe 'POST /decisions' do
    let(:moderator) { create(:moderator) }
    let(:other_moderator) { create(:moderator) }
    let(:comment) { create(:comment) }
    let(:report) do
      create(:report, :for_comment, target_comment: comment, reason_type: 'harassment', reason_text: '嫌がらせコメントです')
    end

    # リクエストレベルの重複であって、DBレベルの重複テストではないことに注意
    context '複数モデレーターが同時に同じ通報を処理した場合' do
      it '先に処理した決定のみが有効になること' do
        sign_in moderator

        post '/decisions', params: {
          decision: {
            report_id: report.id,
            decision_type: 'hide_comment',
            note: '最初のモデレーターによる決定'
          }
        }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response).to redirect_to(reports_path(target_type: report.target_type))
        expect(flash[:notice]).to eq(I18n.t('flash.actions.create.notice', resource: Decision.model_name.human))

        sign_out moderator

        sign_in other_moderator

        post '/decisions', params: {
          decision: {
            report_id: report.id,
            decision_type: 'reject',
            note: '2番目のモデレーターによる決定'
          }
        }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response).to have_http_status(:unprocessable_entity)

        expect(Decision.where(report_id: report.id).count).to eq(1)
        expect(Decision.find_by(report_id: report.id).note).to eq('最初のモデレーターによる決定')
      end
    end
  end
end
