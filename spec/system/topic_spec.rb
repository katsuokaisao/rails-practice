# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'トピック', type: :system do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:suspended_user) { create(:user, :suspended) }
  let!(:topic) { create(:topic, author: user, title: 'テストトピック') }
  let!(:other_topic) { create(:topic, author: other_user, title: '他のユーザーのトピック') }
  let(:long_x_special_char_topic) { create(:topic, author: user, title: "#{'a' * 118}👉＠") }

  context '未ログインユーザー' do
    it 'トピック一覧を閲覧できる' do
      visit topics_path

      expect(page).to have_content('テストトピック')
      expect(page).to have_content('他のユーザーのトピック')
      expect(page).not_to have_link('新規トピック作成')
      expect(page).not_to have_selector('.edit-actions')
    end

    it 'トピック詳細を閲覧できる' do
      create_list(:comment, 20, :short_content, topic: topic)
      visit topic_path(topic)

      within('.topic-show') do
        expect(page).to have_content('テストトピック')
        expect(page).to have_content("作成者: #{user.nickname}")
        expect(page).to have_content("作成日: #{topic.created_at.strftime('%Y-%m-%d %H:%M')}")
      end

      within('.comment-list') do
        expect(page).to have_content(Comment.first.content)
        expect(page).to have_content(Comment.last.content)
      end

      expect(page).not_to have_content('コメントを投稿する')
      expect(page).to have_selector('.back-button-container')
      click_link 'arrow_back'
      expect(page).to have_content('お題 一覧')
    end

    it '新規トピック作成ページにアクセスできない' do
      visit new_topic_path
      expect(page).to have_content('アクセスが禁止されています。')
    end
  end

  context 'ログインユーザ' do
    scenario 'ログインユーザーが新規トピックを作成し、編集できる' do
      login_as(user)
      visit topics_path
      expect(page).to have_content('お題 一覧')
      click_link 'お題を投稿する'
      expect(page).to have_content('お題 新規作成')
      fill_in 'タイトル', with: '新しいトピック'
      click_button '登録する'
      expect(page).to have_content('お題が作成されました。')
      within('.topic-show') do
        expect(page).to have_content('新しいトピック')
        expect(page).to have_content("作成者: #{user.nickname}")
        expect(page).to have_content("作成日: #{topic.created_at.strftime('%Y-%m-%d %H:%M')}")
      end
    end

    scenario 'ログインユーザーが自分のトピックを編集できる' do
      login_as(user)
      visit topic_path(topic)
      expect(page).to have_link('edit')
      click_link 'edit'
      expect(page).to have_content('お題 編集')
      fill_in 'タイトル', with: '編集されたトピック'
      click_button '更新する'
      expect(page).to have_content('お題が更新されました。')
      within('.topic-show') do
        expect(page).to have_content('編集されたトピック')
        expect(page).to have_content("作成者: #{user.nickname}")
        expect(page).to have_content("作成日: #{topic.created_at.strftime('%Y-%m-%d %H:%M')}")
      end
    end

    scenario 'ログインユーザーは他のユーザーのトピックを編集できない' do
      login_as(user)
      visit topic_path(other_topic)
      expect(page).not_to have_link('edit')
      visit edit_topic_path(other_topic)
      expect(page).to have_content('アクセスが禁止されています。')
    end

    scenario 'トピック作成時の入力バリデーションが機能する' do
      login_as(user)
      visit new_topic_path

      fill_in 'タイトル', with: ''
      click_button '登録する'
      expect(page).to have_content('タイトルは1文字以上で入力してください')

      fill_in 'タイトル', with: 'a' * 121
      click_button '登録する'
      expect(page).to have_content('タイトルは120文字以内で入力してください')

      fill_in 'タイトル', with: '<h1>HTMLタイトル</h1>'
      click_button '登録する'
      expect(page).to have_content('タイトルHTMLタグは使用できません')
    end

    scenario 'トピック編集時の入力バリデーションが機能する' do
      login_as(user)
      visit edit_topic_path(topic)

      fill_in 'タイトル', with: ''
      click_button '更新する'
      expect(page).to have_content('タイトルは1文字以上で入力してください')

      fill_in 'タイトル', with: 'a' * 121
      click_button '更新する'
      expect(page).to have_content('タイトルは120文字以内で入力してください')

      fill_in 'タイトル', with: '<h1>HTMLタイトル</h1>'
      click_button '更新する'
      expect(page).to have_content('タイトルHTMLタグは使用できません')
    end
  end

  context '停止されたユーザー' do
    it '停止されたユーザーは新規トピックを作成できない' do
      login_as(suspended_user)
      visit topics_path
      expect(page).not_to have_link('お題を投稿する')
      visit new_topic_path
      expect(page).to have_content('アクセスが禁止されています。')
    end

    it '停止されたユーザーは自分のトピックを編集できない' do
      login_as(suspended_user)
      visit topic_path(topic)
      expect(page).not_to have_link('edit')
      visit edit_topic_path(topic)
      expect(page).to have_content('アクセスが禁止されています。')
    end
  end

  context 'ページネーション' do
    it 'トピック一覧のページネーションが機能する' do
      create_list(:topic, 30, author: user)

      topic = Topic.order(created_at: :desc).last
      visit topics_path
      expect(page).to have_selector('.pagination')
      click_link '2'
      expect(page).to have_content(topic.title)
      expect(page).to have_content("作成者: #{topic.author.nickname}")
      expect(page).to have_content("作成日: #{topic.created_at.strftime('%Y-%m-%d %H:%M')}")
      visit topics_path(page: 999)
      expect(page).to have_content('範囲外のリクエストです。')
    end

    it 'トピック詳細ページのコメントページネーションが機能する' do
      create_list(:comment, 30, :short_content, topic: topic)

      visit topic_path(topic)
      expect(page).to have_selector('.pagination')
      click_link '2'
      comment = topic.comments.order(created_at: :desc).last
      expect(page).to have_content(comment.content)
      expect(page).to have_content(comment.author.nickname)
      expect(page).to have_content("作成日: #{comment.created_at.strftime('%Y-%m-%d %H:%M')}")
      visit topic_path(topic, page: 999)
      expect(page).to have_content('範囲外のリクエストです。')
    end
  end

  it '長いタイトルや特殊文字を含むトピックが正しく表示される' do
    long_x_special_char_topic

    visit topics_path
    expect(page).to have_content(long_x_special_char_topic.title)

    visit topic_path(long_x_special_char_topic)
    expect(page).to have_content(long_x_special_char_topic.title)
  end
end
