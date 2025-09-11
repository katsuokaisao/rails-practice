# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'コメント', type: :system do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:suspended_user) { create(:user, :suspended) }
  let!(:moderator) { create(:moderator) }
  let!(:topic) { create(:topic, author: user, title: 'テストトピック') }
  let!(:suspended_user_topic) { create(:topic, author: suspended_user, title: '停止ユーザーのトピック') }
  let!(:comment) { create(:comment, topic: topic, author: user, content: 'テストコメント') }
  let!(:other_comment) { create(:comment, topic: topic, author: other_user, content: '他のユーザーのコメント') }

  scenario '未ログインユーザーがコメントを投稿できない' do
    visit topic_path(topic)
    expect(page).not_to have_content('コメントを投稿する')
  end

  scenario '未ログインユーザーはコメントを編集できない' do
    visit topic_path(topic)
    expect(page).not_to have_link('編集', href: edit_topic_comment_path(comment.topic, comment))
    visit edit_topic_comment_path(comment.topic, comment)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'ログインユーザーがコメントを投稿できる' do
    login_as(user)
    visit topic_path(topic)
    expect(page).to have_content('コメントを投稿する')
    fill_in 'コメント', with: '新しいコメント'
    click_button 'コメントを投稿する'
    expect(page).to have_content('コメントが投稿されました。')
    expect(page).to have_content('新しいコメント')
  end

  scenario 'ログインユーザーが自分のコメントを編集できる' do
    login_as(user)
    visit topic_path(topic)
    click_link '編集', href: edit_topic_comment_path(comment.topic, comment)
    expect(page).to have_content('編集')
    sleep(1)
    fill_in 'コメント内容', with: '変更後のコメント'
    click_button '更新する'
    expect(page).to have_content('コメントが更新されました。')
    expect(page).to have_content('コメント編集履歴')
    expect(page).to have_content('変更後のコメント')
  end

  scenario 'ログインユーザーは他のユーザーのコメントを編集できない' do
    visit topic_path(topic)
    expect(page).not_to have_link('edit', href: edit_topic_comment_path(other_comment.topic, other_comment))
    visit edit_topic_comment_path(other_comment.topic, other_comment)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'コメント投稿時の入力バリデーションが機能する' do
    login_as(user)
    visit topic_path(topic)
    expect(page).to have_content('コメントを投稿する')

    fill_in 'コメント', with: ''
    click_button 'コメントを投稿する'
    expect(page).to have_content('コメント内容を入力してください')

    fill_in 'コメント', with: 'a' * 5001
    click_button 'コメントを投稿する'
    expect(page).to have_content('コメント内容は5000文字以内で入力してください')

    fill_in 'コメント', with: '<script>alert("XSS")</script>'
    click_button 'コメントを投稿する'
    expect(page).to have_content('alert("XSS")')
  end

  scenario 'コメント編集時の入力バリデーションが機能する' do
    login_as(user)
    visit topic_path(topic)
    click_link '編集', href: edit_topic_comment_path(comment.topic, comment)
    expect(page).to have_content('編集')

    sleep(1)
    fill_in 'コメント内容', with: ''
    click_button '更新する'
    expect(page).to have_content('コメント内容を入力してください')

    fill_in 'コメント内容', with: 'a' * 5001
    click_button '更新する'
    expect(page).to have_content('コメント内容は5000文字以内で入力してください')

    fill_in 'コメント内容', with: '<script>alert("XSS")</script>'
    click_button '更新する'
    expect(page).to have_content('alert("XSS")')
  end

  scenario '停止されたユーザーはコメントを投稿できない' do
    login_as(suspended_user)
    visit topic_path(topic)
    expect(page).not_to have_content('コメントを投稿する')
  end

  scenario '停止されたユーザーは自分のコメントを編集できない' do
    login_as(suspended_user)
    visit topic_path(suspended_user_topic)
    expect(page).not_to have_link('edit', href: edit_topic_comment_path(comment.topic, comment))
    visit edit_topic_comment_path(comment.topic, comment)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario '長い文字と特殊文字を含むコメントが正しく表示される' do
    create(:comment, topic: topic, author: user, content: "#{'a' * 4998}👉＠")
    visit topic_path(topic)
    expect(page).to have_content("#{'a' * 4998}👉＠")
  end

  scenario 'コメントを複数回編集した後も公開画面では常に最新版のみが表示されることの確認' do
    login_as(user)
    visit topic_path(topic)
    expect(page).to have_content('テストコメント')

    click_link '編集', href: edit_topic_comment_path(topic, comment)
    expect(page).to have_content('編集')
    sleep(1)
    fill_in 'コメント', with: '1回目の編集'
    click_button '更新する'
    visit topic_path(topic)
    expect(page).to have_content('1回目の編集')

    visit edit_topic_comment_path(topic, comment)
    fill_in 'コメント', with: '2回目の編集'
    click_button '更新する'
    visit topic_path(topic)
    expect(page).not_to have_content('1回目の編集')
    expect(page).to have_content('2回目の編集')

    visit edit_topic_comment_path(topic, comment)
    fill_in 'コメント', with: '3回目の編集（最新版）'
    click_button '更新する'
    visit topic_path(topic)
    expect(page).to have_content('3回目の編集（最新版）')
    expect(page).not_to have_content('1回目の編集')
    expect(page).not_to have_content('2回目の編集')

    visit comment_histories_path(comment)
    expect(page).to have_content('コメント編集履歴')
    expect(page).to have_content('1回目の編集')
    expect(page).to have_content('2回目の編集')
    expect(page).to have_content('3回目の編集（最新版）')
  end

  scenario 'ユーザーを停止が解除された後のコメント表示状態の確認' do
    create(:report, :for_user, target: user, reason_type: 'harassment', reason_text: '嫌がらせユーザーです')
    login_as(moderator, scope: :moderator)
    visit reports_path

    expect(page).to have_content('通報 一覧')
    click_link 'ユーザー通報'
    expect(page).to have_css('li.active > a', text: 'ユーザー通報')
    expect(page).to have_content('通報 一覧')

    click_link '審査'
    expect(page).to have_content('審査')

    select 'ユーザーを停止', from: '審査種別'
    fill_in 'メモ', with: 'テスト用に停止'
    click_button '1日'
    click_button '確定'
    expect(page).to have_content('審査が作成されました。')
    logout

    login_as(user)
    visit topic_path(topic)
    expect(page).not_to have_content('通報対象コメント')
    expect(page).to have_content('規約違反の可能性があるため、アカウントが停止されています。')

    user.enforce_release_suspension!

    visit topic_path(topic)
    expect(page).to have_content('テストコメント')
  end

  scenario '停止中ユーザーの非表示コメントの状態確認（二重制約の確認）' do
    create(:report, :for_comment, target: comment, reason_type: 'harassment', reason_text: '嫌がらせコメントです')

    login_as(moderator, scope: :moderator)
    visit reports_path

    click_link '審査'
    expect(page).to have_content('審査')

    select 'コメントを非表示', from: '審査種別'
    fill_in 'メモ', with: 'テスト用に非表示'
    click_button '確定'
    expect(page).to have_content('審査が作成されました。')

    create(:report, :for_user, target: user, reason_type: 'harassment', reason_text: '嫌がらせユーザーです')

    visit reports_path
    click_link 'ユーザー通報'

    expect(page).to have_css('li.active > a', text: 'ユーザー通報')
    click_link '審査'
    expect(page).to have_content('審査')

    select 'ユーザーを停止', from: '審査'
    fill_in 'メモ', with: 'テスト用に停止'
    click_button '1日'
    click_button '確定'
    expect(page).to have_content('審査が作成されました。')

    logout
    login_as(other_user)

    # アカウント停止中かつコメント非表示のため、コメントの内容が非表示になっていることを確認
    visit topic_path(topic)
    expect(page).not_to have_content('通報対象コメント')
    expect(page).to have_content('このコメントは非表示です。')

    user.enforce_release_suspension!
    expect(user.reload).not_to be_suspended

    # アカウントの停止が解除されたが、コメント非表示は継続されていることを確認
    visit topic_path(topic)
    expect(page).to have_content('このコメントは非表示です。')
  end

  scenario 'コメント数が正しく表示されることの確認' do
    topic = create(:topic, author: user, title: 'テストトピック1')

    visit topic_path(topic)
    expect(page).to have_content('コメント数: 0件')

    Comment.create_with_history!(
      topic: topic,
      author: user,
      content: 'テストコメント1'
    )

    visit topic_path(topic)
    expect(page).to have_content('コメント数: 1件')
  end
end
