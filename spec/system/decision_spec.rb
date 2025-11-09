# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '審査', type: :system do
  let!(:tenant) { create(:tenant) }
  let!(:user) { create(:user) }
  let!(:reported_user) { create(:user) }
  let!(:moderator) { create(:moderator, tenant: tenant) }
  let!(:user_membership) { create(:tenant_membership, tenant: tenant, user: user, display_name: 'ユーザー1') }
  let!(:reported_user_membership) do
    create(:tenant_membership, tenant: tenant, user: reported_user, display_name: 'ユーザー2')
  end
  let!(:topic) { create(:topic, tenant: tenant, author: user, title: 'テストトピック') }
  let!(:comment) { create(:comment, topic: topic, author: reported_user, content: '報告対象コメント') }
  let!(:comment_report) do
    create(:report, tenant: tenant, reportable: comment, reporter: user, reason_type: 'spam')
  end
  let!(:user_report) do
    create(:report, tenant: tenant, reportable: reported_user, reporter: user, reason_type: 'harassment')
  end
  let!(:user_report_decision) do
    create(:decision, :suspend_user, tenant: tenant, report: user_report, decider: moderator)
  end
  let!(:comment_report_decision) do
    create(:decision, :hide_comment, tenant: tenant, report: comment_report, decider: moderator)
  end

  scenario '未ログインユーザーが審査一覧を閲覧できない' do
    visit tenant_decisions_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario '一般ユーザーが審査一覧を閲覧できない' do
    login_as(user)
    visit tenant_decisions_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'モデレーターが審査一覧を閲覧できる' do
    login_as(moderator, scope: :moderator)
    visit tenant_decisions_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('審査 一覧')

    expect(page).to have_css('li.active a', text: 'コメント通報審査')
    within('.decisions-container') do
      expect(page).to have_content(user_membership.display_name)
      expect(page).to have_content(comment_report_decision.report.enum_i18n(:reason_type))
      expect(page).to have_content(comment_report_decision.report.reason_text)
      expect(page).to have_content(comment_report_decision.report.reportable.topic.title)
      expect(page).to have_content(reported_user_membership.display_name)
      expect(page).to have_content(comment_report_decision.enum_i18n(:decision_type))
      expect(page).to have_content(comment_report_decision.note)
      expect(page).to have_content(comment_report_decision.decider.login_id)
      expect(page).to have_content(comment_report_decision.created_at.strftime('%Y/%m/%d %H:%M'))
    end

    click_link 'ユーザー通報審査'
    expect(page).to have_css('li.active a', text: 'ユーザー通報審査')
    within('.decisions-container') do
      expect(page).to have_content(user_membership.display_name)
      expect(page).to have_content(user_report_decision.report.enum_i18n(:reason_type))
      expect(page).to have_content(user_report_decision.report.reason_text)
      expect(page).to have_content(reported_user_membership.display_name)
      expect(page).to have_content(user_report_decision.enum_i18n(:decision_type))
      expect(page).to have_content(user_report_decision.note)
      expect(page).to have_content(user_report_decision.suspended_until.strftime('%Y/%m/%d %H:%M'))
      expect(page).to have_content(user_report_decision.decider.login_id)
      expect(page).to have_content(user_report_decision.created_at.strftime('%Y/%m/%d %H:%M'))
    end
  end

  scenario '審査のページネーションが機能する' do
    create_list(:decision, 21, :hide_comment, tenant: tenant, decider: moderator)

    login_as(moderator, scope: :moderator)
    visit tenant_decisions_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('審査 一覧')

    within('.pagination') do
      click_link '2'
    end
    within('.decisions-container') do
      expect(page).to have_css('tr', minimum: 1)
      expect(page).to have_content('コメントを非表示')
    end

    visit tenant_decisions_path(tenant_slug: tenant.identifier, page: 999)
    expect(page).to have_content('範囲外のリクエストです。')
  end
end
