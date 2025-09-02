# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'レポート', type: :system do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:moderator) { create(:moderator) }
  let!(:topic) { create(:topic, author: user, title: 'テストトピック') }
  let!(:comment) { create(:comment, topic: topic, content: 'レポート対象コメント') }

  scenario '未ログインユーザーがレポートを作成できない' do
    visit topic_path(topic)
    expect(page).not_to have_link('違法ユーザ')
    expect(page).not_to have_link('コメントの非表示')
  end

  scenario 'ログインユーザーがコメントをレポートできる' do
    login_as user
    visit topic_path(topic)
    expect(page).to have_content('テストトピック')
    click_link 'コメントの非表示'
    expect(page).to have_content('通報の申請')
    select 'スパム', from: '理由タイプ'
    fill_in '理由（詳細）', with: '詳細な理由'
    click_button '通報を確定'
    expect(page).to have_content('通報が作成されました。')
    expect(page).not_to have_content('通報の申請')
  end

  scenario 'ログインユーザーがユーザーをレポートできる' do
    login_as user
    visit topic_path(topic)
    expect(page).to have_content('テストトピック')
    click_link '違法ユーザ'
    expect(page).to have_content('通報の申請')
    select 'スパム', from: '理由タイプ'
    fill_in '理由（詳細）', with: '詳細な理由'
    click_button '通報を確定'
    expect(page).to have_content('通報が作成されました。')
    expect(page).not_to have_content('通報の申請')
  end

  scenario 'レポート作成時の入力バリデーションが機能する' do
    login_as user
    visit topic_path(topic)
    expect(page).to have_content('テストトピック')
    click_link 'コメントの非表示'
    expect(page).to have_content('通報の申請')

    select 'スパム', from: '理由タイプ'
    fill_in '理由（詳細）', with: 'a' * 2001
    click_button '通報を確定'
    expect(page).to have_content('理由詳細は2000文字以内で入力してください')
  end

  scenario '未ログインユーザーがレポート一覧を閲覧できない' do
    visit reports_path
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario '一般ユーザーがレポート一覧を閲覧できない' do
    login_as user
    visit reports_path
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'モデレーターがレポート一覧を閲覧できる' do
    comment_report = create(:report, :for_comment, reason_type: 'harassment', reason_text: '嫌がらせコメントです')

    login_as(moderator, scope: :moderator)

    visit reports_path
    expect(page).to have_content('通報 一覧')
    expect(page).to have_css('li.active a', text: 'コメント通報')

    within('.reports-table') do
      expect(page).to have_content(comment_report.reporter.nickname)
      expect(page).to have_content('嫌がらせ')
      expect(page).to have_content(comment_report.reason_text)
      expect(page).to have_content(comment_report.target_comment.topic.title)
      expect(page).to have_content(comment_report.target_comment.created_at.strftime('%Y-%m-%d %H:%M'))
      expect(page).to have_content(comment_report.target_comment.current_version_no)
      expect(page).to have_content(comment_report.target_comment.author.nickname)
      expect(page).to have_link('審査')
    end
  end

  scenario 'レポートのタブ切り替えが機能する' do
    user_report = create(:report, :for_user, reason_type: 'spam', reason_text: 'スパムユーザーです')

    login_as(moderator, scope: :moderator)

    visit reports_path
    expect(page).to have_content('通報 一覧')

    click_link 'ユーザー通報'
    within('.reports-table') do
      expect(page).to have_content(user_report.reporter.nickname)
      expect(page).to have_content('スパム')
      expect(page).to have_content(user_report.reason_text)
      expect(page).to have_content(user_report.target_user.nickname)
      expect(page).to have_content(user_report.created_at.strftime('%Y-%m-%d %H:%M'))
      expect(page).to have_link('審査')
    end
  end

  scenario 'レポートのページネーションが機能する' do
    create_list(:report, 21, :for_comment)
    comment_report = Report.order(created_at: :desc).last

    login_as(moderator, scope: :moderator)

    visit reports_path
    expect(page).to have_content('通報 一覧')

    click_link '2'
    expect(page).to have_content('通報 一覧')
    expect(page).to have_content(comment_report.reason_text)

    visit reports_path(page: 999)
    expect(page).to have_content('範囲外のリクエストです。')
  end

  scenario '既に報告済みのコメントを再度報告しようとした場合の処理' do
    login_as user
    visit topic_path(topic)
    expect(page).to have_content('テストトピック')
    click_link 'コメントの非表示'
    expect(page).to have_content('通報の申請')
    select 'スパム', from: '理由タイプ'
    fill_in '理由（詳細）', with: '最初のユーザーからの報告'
    click_button '通報を確定'
    expect(page).to have_content('通報が作成されました。')
    logout

    login_as other_user
    visit topic_path(topic)
    expect(page).to have_content('テストトピック')
    click_link 'コメントの非表示'
    expect(page).to have_content('通報の申請')
    select '嫌がらせ', from: '理由タイプ'
    fill_in '理由（詳細）', with: '別のユーザーからの報告'
    click_button '通報を確定'
    expect(page).to have_content('通報が作成されました。')
    logout

    login_as(moderator, scope: :moderator)
    visit reports_path
    expect(page).to have_content('最初のユーザーからの報告')
    expect(page).to have_content('別のユーザーからの報告')
    expect(page).to have_content(user.nickname)
    expect(page).to have_content(other_user.nickname)
  end

  scenario '既に決定済みのレポートがレポート一覧に表示されない' do
    report = create(:report, :for_comment)

    login_as(moderator, scope: :moderator)
    visit reports_path
    expect(page).to have_content(report.reason_text)

    click_link '審査'
    expect(page).to have_content('通報審査')
    select '却下', from: '審査種類'
    fill_in 'メモ', with: '審査メモ'
    click_button '審査を確定'

    visit reports_path
    expect(page).not_to have_content(report.reason_text)
  end

  scenario 'レポートモーダルのキャンセルボタンが機能する' do
    login_as user
    visit topic_path(topic)
    expect(page).to have_content('テストトピック')
    click_link 'コメントの非表示'
    expect(page).to have_content('通報の申請')
    select 'スパム', from: '理由タイプ'
    fill_in '理由（詳細）', with: '最初のユーザーからの報告'
    click_button 'キャンセル'
    expect(page).not_to have_content('通報の申請')
    expect(page).to have_content('テストトピック')
  end
end
