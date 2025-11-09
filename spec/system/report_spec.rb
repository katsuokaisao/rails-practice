# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '通報', type: :system do
  let!(:tenant) { create(:tenant) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:moderator) { create(:moderator, tenant: tenant) }

  let!(:user_membership) { create(:tenant_membership, tenant: tenant, user: user, display_name: 'ユーザー1') }
  let!(:other_user_membership) { create(:tenant_membership, tenant: tenant, user: other_user, display_name: 'ユーザー2') }

  let!(:topic) { create(:topic, tenant: tenant, author: user, title: 'テストトピック') }
  let!(:comment) { create(:comment, topic: topic, content: '通報対象コメント') }

  scenario '未ログインユーザーが通報を作成できない' do
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_link('違法ユーザ')
    expect(page).not_to have_link('コメントを非表示')
  end

  scenario 'ログインユーザーがコメントを通報できる' do
    login_as user
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('テストトピック')
    click_link 'コメントを非表示'
    expect(page).to have_content('通報の申請')
    select 'スパム', from: '理由種別'
    fill_in '理由詳細', with: '詳細な理由'
    click_button '確定'
    expect(page).to have_content('通報が作成されました。')
    expect(page).not_to have_content('通報の申請')
  end

  scenario 'ログインユーザーがユーザーを通報できる' do
    login_as user
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('テストトピック')
    click_link '違法ユーザ'
    expect(page).to have_content('通報の申請')
    select 'スパム', from: '理由種別'
    fill_in '理由詳細', with: '詳細な理由'
    click_button '確定'
    expect(page).to have_content('通報が作成されました。')
    expect(page).not_to have_content('通報の申請')
  end

  scenario '通報作成時の入力バリデーションが機能する' do
    login_as user
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('テストトピック')
    click_link 'コメントを非表示'
    expect(page).to have_content('通報の申請')

    select 'スパム', from: '理由種別'
    fill_in '理由詳細', with: 'a' * 2001
    click_button '確定'
    expect(page).to have_content('理由詳細は2000文字以内で入力してください')
  end

  scenario '未ログインユーザーが通報一覧を閲覧できない' do
    visit tenant_reports_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario '一般ユーザーが通報一覧を閲覧できない' do
    login_as user
    visit tenant_reports_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'モデレーターが通報一覧を閲覧できる' do
    comment_report = create(:report, :for_comment, tenant: tenant, reason_type: 'harassment', reason_text: '嫌がらせコメントです')

    login_as(moderator, scope: :moderator)

    visit tenant_reports_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('通報 一覧')
    expect(page).to have_css('li.active a', text: 'コメント通報')

    within('.reports-table') do
      expect(page).to have_content(comment_report.reporter.login_id)
      expect(page).to have_content('嫌がらせ')
      expect(page).to have_content(comment_report.reason_text)
      expect(page).to have_content(comment_report.reportable.topic.title)
      expect(page).to have_content(comment_report.reportable.created_at.strftime('%Y/%m/%d %H:%M'))
      expect(page).to have_content(comment_report.reportable.current_version_no)
      expect(page).to have_content(comment_report.reportable.author.login_id)
      expect(page).to have_link('審査')
    end
  end

  scenario '通報のタブ切り替えが機能する' do
    user_report = create(:report, :for_user, tenant: tenant, reason_type: 'spam', reason_text: 'スパムユーザーです')

    login_as(moderator, scope: :moderator)

    visit tenant_reports_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('通報 一覧')

    click_link 'ユーザー通報'
    within('.reports-table') do
      expect(page).to have_content(user_report.reporter.login_id)
      expect(page).to have_content('スパム')
      expect(page).to have_content(user_report.reason_text)
      expect(page).to have_content(user_report.reportable.login_id)
      expect(page).to have_content(user_report.created_at.strftime('%Y/%m/%d %H:%M'))
      expect(page).to have_link('審査')
    end
  end

  scenario '通報のページネーションが機能する' do
    create_list(:report, 21, :for_comment, tenant: tenant)
    comment_report = Report.order(created_at: :desc).last

    login_as(moderator, scope: :moderator)

    visit tenant_reports_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('通報 一覧')

    click_link '2'
    expect(page).to have_content('通報 一覧')
    expect(page).to have_content(comment_report.reason_text)

    visit tenant_reports_path(tenant_slug: tenant.identifier, page: 999)
    expect(page).to have_content('範囲外のリクエストです。')
  end

  scenario '既に報告済みのコメントを再度報告しようとした場合の処理' do
    login_as user
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('テストトピック')
    click_link 'コメントを非表示'
    expect(page).to have_content('通報の申請')
    select 'スパム', from: '理由種別'
    fill_in '理由詳細', with: '最初のユーザーからの報告'
    click_button '確定'
    expect(page).to have_content('通報が作成されました。')
    logout

    login_as other_user
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('テストトピック')
    click_link 'コメントを非表示'
    expect(page).to have_content('通報の申請')
    select '嫌がらせ', from: '理由種別'
    fill_in '理由詳細', with: '別のユーザーからの報告'
    click_button '確定'
    expect(page).to have_content('通報が作成されました。')
    logout

    login_as(moderator, scope: :moderator)
    visit tenant_reports_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('最初のユーザーからの報告')
    expect(page).to have_content('別のユーザーからの報告')
    expect(page).to have_content(user.login_id)
    expect(page).to have_content(other_user.login_id)
  end

  scenario '既に審査済みの通報が通報一覧に表示されない' do
    report = create(:report, :for_comment, tenant: tenant)

    login_as(moderator, scope: :moderator)
    visit tenant_reports_path(tenant_slug: tenant.identifier)
    expect(page).to have_content(report.reason_text)

    click_link '審査'
    expect(page).to have_content('審査')
    select '却下', from: '審査種別'
    fill_in 'メモ', with: '審査メモ'
    accept_confirm do
      click_button '確定'
    end

    visit tenant_reports_path(tenant_slug: tenant.identifier)
    expect(page).not_to have_content(report.reason_text)
  end

  scenario '通報モーダルのキャンセルボタンが機能する' do
    login_as user
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('テストトピック')
    click_link 'コメントを非表示'
    expect(page).to have_content('通報の申請')
    select 'スパム', from: '理由種別'
    fill_in '理由詳細', with: '最初のユーザーからの報告'
    click_button '閉じる'
    expect(page).not_to have_content('通報の申請')
    expect(page).to have_content('テストトピック')
  end

  scenario '非表示コメントが公開画面に表示されないことの確認' do
    comment = create(:comment, topic: topic, author: user, content: 'テスト用の非表示コメント')
    create(:report, :for_comment,
           tenant: tenant, reportable: comment, reason_type: 'harassment', reason_text: '嫌がらせコメントです')

    login_as(moderator, scope: :moderator)
    visit tenant_reports_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('嫌がらせコメントです')
    click_link '審査'
    expect(page).to have_content('審査')
    select 'コメントを非表示', from: '審査種別'
    fill_in 'メモ', with: 'テスト用に非表示'
    accept_confirm do
      click_button '確定'
    end
    expect(page).to have_content('審査が作成されました。')
    logout

    login_as(other_user)
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)

    expect(page).not_to have_content('テスト用の非表示コメント')
    expect(page).to have_content('このコメントは非表示です。')
    logout

    login_as(user)
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_content('テスト用の非表示コメント')
    expect(page).to have_content('規約違反の可能性があるため、あなたのコメントは非表示になりました。')
  end

  scenario '非表示コメントを編集しても公開画面には表示されないことの確認' do
    comment = create(:comment, topic: topic, author: other_user, content: 'テスト用の非表示コメント')
    create(:report, :for_comment,
           tenant: tenant, reportable: comment, reason_type: 'harassment', reason_text: '嫌がらせコメントです')

    login_as(moderator, scope: :moderator)
    visit tenant_reports_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('嫌がらせコメントです')

    click_link '審査'
    expect(page).to have_content('審査')

    select 'コメントを非表示', from: '審査種別'
    fill_in 'メモ', with: 'テスト用に非表示'
    accept_confirm do
      click_button '確定'
    end
    expect(page).to have_content('審査が作成されました。')
    logout

    login_as(other_user)
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_content('テスト用の非表示コメント')
    expect(page).to have_content('規約違反の可能性があるため、あなたのコメントは非表示になりました。')

    click_link '編集',
               href: edit_tenant_topic_comment_path(tenant_slug: tenant.identifier,
                                                    topic_id: comment.topic.id, id: comment.id)
    expect(page).to have_content('編集')
    sleep(1)
    fill_in 'コメント内容', with: '変更後のコメント'
    click_button '更新する'
    expect(page).to have_content('コメントが更新されました。')
    expect(page).to have_content('コメント編集履歴')
    expect(page).to have_content('変更後のコメント')

    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_content('テスト用の非表示コメント')
    expect(page).to have_content('規約違反の可能性があるため、あなたのコメントは非表示になりました。')

    logout
  end
end
