# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Decisions', type: :request do
  describe 'POST /:tenant_slug/decisions' do
    let(:tenant) { create(:tenant) }
    let(:moderator) { create(:moderator, tenant: tenant) }
    let(:other_moderator) { create(:moderator, tenant: tenant) }
    let(:user) { create(:user) }
    let(:user_membership) { create(:tenant_membership, tenant: tenant, user: user) }
    let(:topic) { create(:topic, tenant: tenant, author: user) }
    let(:comment) { create(:comment, topic: topic, author: user) }
    let(:harassment_reason) { create(:ban_reason, tenant: tenant) }
    let(:report) do
      create(:report, :for_comment,
             tenant: tenant, reportable: comment, reporter: user, ban_reason: harassment_reason,
             reason_text: '嫌がらせコメントです')
    end

    # リクエストレベルの重複であって、DBレベルの重複テストではないことに注意
    context '複数モデレーターが同時に同じ通報を処理した場合' do
      it '先に処理した審査のみが有効になること' do
        login_as(moderator, scope: :moderator)

        post "/#{tenant.slug}/decisions", params: {
          decision: {
            report_id: report.id,
            decision_type: 'hide_comment',
            note: '最初のモデレーターによる審査'
          }
        }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response).to redirect_to(tenant_reports_path(tenant_slug: tenant.slug,
                                                            reportable_type: report.reportable_type.downcase))
        expect(flash[:notice]).to eq(I18n.t('flash.actions.create.notice', resource: Decision.model_name.human))

        logout moderator

        login_as other_moderator, scope: :moderator

        post "/#{tenant.slug}/decisions", params: {
          decision: {
            report_id: report.id,
            decision_type: 'reject',
            note: '2番目のモデレーターによる審査'
          }
        }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response).to have_http_status(:unprocessable_content)

        expect(Decision.where(report_id: report.id).count).to eq(1)
        expect(Decision.find_by(report_id: report.id).note).to eq('最初のモデレーターによる審査')
      end
    end
  end
end
