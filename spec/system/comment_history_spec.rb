# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'コメント履歴', type: :system do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:moderator) { create(:moderator) }
  let!(:topic) { create(:topic, author: user, title: 'テストトピック') }
  let!(:comment) { create(:comment, topic: topic, author: user, content: '初回コメント') }
  let!(:other_comment) { create(:comment, topic: topic, author: other_user, content: '他のユーザーのコメント') }

  before do
    comment.update_content!('2回目の編集')
    comment.update_content!('3回目の編集')
    other_comment.update_content!('他のユーザーのコメント 2回目の編集')
    other_comment.update_content!('他のユーザーのコメント 3回目の編集')
  end

  scenario '未ログインユーザーがコメント履歴を閲覧できない' do
    visit topic_path(topic)
    expect(page).not_to have_link('履歴', href: comment_histories_path(comment))
    visit comment_histories_path(comment)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'ログインユーザーが自分のコメント履歴を閲覧できる' do
    login_as(user)
    visit comment_histories_path(comment)
    expect(page).to have_content('コメント編集履歴')
    expect(page).to have_content('初回コメント')
    expect(page).to have_content('2回目の編集')
    expect(page).to have_content('3回目の編集')
    expect(page).to have_content('バージョン: 1')
    expect(page).to have_content('バージョン: 2')
    expect(page).to have_content('バージョン: 3')
  end

  scenario 'ログインユーザーは他のユーザーのコメント履歴を閲覧できない' do
    login_as(user)
    visit topic_path(topic)
    expect(page).not_to have_link('履歴', href: comment_histories_path(other_comment))
    visit comment_histories_path(other_comment)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'モデレーターは全てのコメント履歴を閲覧できる' do
    login_as(moderator, scope: :moderator)
    visit comment_histories_path(comment)
    expect(page).to have_content('コメント編集履歴')
    expect(page).to have_content('初回コメント')
    expect(page).to have_content('バージョン: 1')

    visit comment_histories_path(other_comment)
    expect(page).to have_content('コメント編集履歴')
    expect(page).to have_content('他のユーザーのコメント')
    expect(page).to have_content('バージョン: 1')
  end

  scenario 'コメント履歴の比較機能が正しく動作する' do
    login_as(user)
    visit comment_histories_path(comment)
    select '1', from: 'From:'
    select '2', from: 'To:'
    click_button '選択したバージョンを比較'
    expect(page).to have_content('コメント編集履歴の比較')
    expect(page).to have_content('バージョン: 1')
    expect(page).to have_content('バージョン: 2')
  end

  scenario '同じバージョンを比較しようとするとエラーになる' do
    login_as(user)
    visit comment_histories_path(comment)
    select '1', from: 'From:'
    select '1', from: 'To:'
    click_button '選択したバージョンを比較'
    expect(page).to have_content('同じバージョンを選択することはできません。異なるバージョンを選択してください。')
  end

  scenario 'コメント履歴のページネーションが機能する' do
    10.times do |i|
      comment.update_content!("#{i + 1}回目の編集")
    end
    login_as(user)
    visit comment_histories_path(comment)
    expect(page).to have_content('コメント編集履歴')
    expect(page).to have_selector('.pagination')

    click_link '2'
    expect(page).to have_content('1回目の編集')

    visit compare_comment_histories_path(comment, page: 999)
    expect(page).to have_content('同じバージョンを選択することはできません。異なるバージョンを選択してください。')
  end
end
