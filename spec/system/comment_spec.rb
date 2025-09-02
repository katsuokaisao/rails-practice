# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'コメント', type: :system do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:suspended_user) { create(:user, :suspended) }
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
    click_button 'コメントする'
    expect(page).to have_content('コメントが投稿されました。')
    expect(page).to have_content('新しいコメント')
  end

  scenario 'ログインユーザーが自分のコメントを編集できる' do
    login_as(user)
    visit topic_path(topic)
    click_link '編集', href: edit_topic_comment_path(comment.topic, comment)
    expect(page).to have_content('コメント 編集')
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

    fill_in 'コメント', with: ''
    click_button 'コメントする'
    expect(page).to have_content('コメント内容を入力してください')

    fill_in 'コメント', with: 'a' * 5001
    click_button 'コメントする'
    expect(page).to have_content('コメント内容は5000文字以内で入力してください')

    fill_in 'コメント', with: '<script>alert("XSS")</script>'
    click_button 'コメントする'
    expect(page).to have_content('alert("XSS")')
  end

  scenario 'コメント編集時の入力バリデーションが機能する' do
    login_as(user)
    visit topic_path(topic)
    click_link '編集', href: edit_topic_comment_path(comment.topic, comment)
    expect(page).to have_content('コメント 編集')

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
end
