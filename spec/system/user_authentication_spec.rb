# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ユーザー認証', type: :system do
  let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }

  describe 'ユーザー登録' do
    it '新規ユーザーが正常に登録できる' do
      visit new_user_registration_path

      fill_in 'user_nickname', with: 'newuser'
      fill_in 'user_password', with: 'password123'
      fill_in 'user_password_confirmation', with: 'password123'

      click_button '登録'

      expect(page).to have_content('アカウント登録が完了しました')
      expect(current_path).to eq(root_path)
    end

    it 'パスワードと確認用パスワードが一致しない場合はエラーが表示される' do
      visit new_user_registration_path

      fill_in 'user_nickname', with: 'newuser'
      fill_in 'user_password', with: 'password123'
      fill_in 'user_password_confirmation', with: 'different_password'

      click_button '登録'

      expect(page).to have_content('パスワード（確認用）とパスワードの入力が一致しません')
    end

    it '既に存在するニックネームでは登録できない' do
      existing_user = create(:user, nickname: 'existing_user')

      visit new_user_registration_path

      fill_in 'user_nickname', with: existing_user.nickname
      fill_in 'user_password', with: 'password123'
      fill_in 'user_password_confirmation', with: 'password123'

      click_button '登録'

      expect(page).to have_content('ニックネームはすでに存在します')
    end
  end

  describe 'ユーザーログイン' do
    it '正しい認証情報でログインできる' do
      visit new_user_session_path

      fill_in 'user_nickname', with: user.nickname
      fill_in 'user_password', with: 'password123'
      click_button 'ログイン'

      expect(page).to have_content('ログインしました')
      expect(current_path).to eq(root_path)

      find('.user-menu-trigger').click
      expect(page).to have_button('ログアウト')
      expect(page).not_to have_link('ユーザーログイン')
      expect(page).not_to have_link('ユーザー登録')
    end

    it '間違ったパスワードではログインできない' do
      visit new_user_session_path

      fill_in 'user_nickname', with: user.nickname
      fill_in 'user_password', with: 'wrong_password'
      click_button 'ログイン'

      expect(page).to have_content('ニックネームまたはパスワードが違います')
    end
  end

  describe 'ユーザーログアウト' do
    it 'ログインボタン押下後にログアウトできる' do
      visit new_user_session_path

      fill_in 'user_nickname', with: user.nickname
      fill_in 'user_password', with: 'password123'
      click_button 'ログイン'

      find('.user-menu-trigger').click
      click_button 'ログアウト'
      expect(page).to have_content('ログアウトしました')
      expect(current_path).to eq(root_path)
    end
  end
end
