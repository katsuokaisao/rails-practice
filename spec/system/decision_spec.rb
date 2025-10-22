# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '審査', type: :system do
  let!(:user) { create(:user) }
  let!(:reported_user) { create(:user) }
  let!(:moderator) { create(:moderator) }
  let!(:topic) { create(:topic, author: user, title: 'テストトピック') }
  let!(:comment) { create(:comment, topic: topic, author: reported_user, content: '報告対象コメント') }
  let!(:comment_report) do
    create(:report, reportable: comment, reporter: user, reason_type: 'spam')
  end
  let!(:user_report) do
    create(:report, reportable: reported_user, reporter: user, reason_type: 'harassment')
  end
  let!(:user_report_decision) { create(:decision, :suspend_user, report: user_report, decider: moderator) }
  let!(:comment_report_decision) { create(:decision, :hide_comment, report: comment_report, decider: moderator) }

  scenario '未ログインユーザーが審査一覧を閲覧できない' do
    visit decisions_path
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario '一般ユーザーが審査一覧を閲覧できない' do
    login_as(user)
    visit decisions_path
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'モデレーターが審査一覧を閲覧できる' do
    login_as(moderator, scope: :moderator)
    visit decisions_path
    expect(page).to have_content('審査 一覧')

    expect(page).to have_css('li.active a', text: 'コメント通報審査')
    within('.decisions-container') do
      expect(page).to have_content(comment_report_decision.report.reporter.nickname)
      expect(page).to have_content(comment_report_decision.report.enum_i18n(:reason_type))
      expect(page).to have_content(comment_report_decision.report.reason_text)
      expect(page).to have_content(comment_report_decision.report.reportable.topic.title)
      expect(page).to have_content(comment_report_decision.report.reportable.author.nickname)
      expect(page).to have_content(comment_report_decision.enum_i18n(:decision_type))
      expect(page).to have_content(comment_report_decision.note)
      expect(page).to have_content(comment_report_decision.decider.nickname)
      expect(page).to have_content(comment_report_decision.created_at.strftime('%Y/%m/%d %H:%M'))
    end

    click_link 'ユーザー通報審査'
    expect(page).to have_css('li.active a', text: 'ユーザー通報審査')
    within('.decisions-container') do
      expect(page).to have_content(user_report_decision.report.reporter.nickname)
      expect(page).to have_content(user_report_decision.report.enum_i18n(:reason_type))
      expect(page).to have_content(user_report_decision.report.reason_text)
      expect(page).to have_content(user_report_decision.report.reportable.nickname)
      expect(page).to have_content(user_report_decision.enum_i18n(:decision_type))
      expect(page).to have_content(user_report_decision.note)
      expect(page).to have_content(user_report_decision.suspended_until.strftime('%Y/%m/%d %H:%M'))
      expect(page).to have_content(user_report_decision.decider.nickname)
      expect(page).to have_content(user_report_decision.created_at.strftime('%Y/%m/%d %H:%M'))
    end
  end

  scenario '審査のページネーションが機能する' do
    create_list(:decision, 21, :hide_comment, decider: moderator)

    login_as(moderator, scope: :moderator)
    visit decisions_path
    expect(page).to have_content('審査 一覧')

    within('.pagination') do
      click_link '2'
    end
    within('.decisions-container') do
      expect(page).to have_css('tr', minimum: 1)
      expect(page).to have_content('コメントを非表示')
    end

    visit decisions_path(page: 999)
    expect(page).to have_content('範囲外のリクエストです。')
  end
end
