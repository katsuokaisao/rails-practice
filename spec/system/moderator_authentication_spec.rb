# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'モデレーター認証', type: :system do
  let(:moderator) { create(:moderator, password: 'password123', password_confirmation: 'password123') }

  describe 'モデレーターログイン' do
    it '正しい認証情報でログインできる' do
      visit new_moderator_session_path

      fill_in 'moderator_login_id', with: moderator.login_id
      fill_in 'moderator_password', with: 'password123'
      click_button 'ログイン'

      expect(page).to have_content('ログインしました')
      expect(current_path).to eq(reports_path)
    end

    it '間違ったパスワードではログインできない' do
      visit new_moderator_session_path

      fill_in 'moderator_login_id', with: moderator.login_id
      fill_in 'moderator_password', with: 'wrong_password'
      click_button 'ログイン'

      expect(page).to have_content('ログインIDまたはパスワードが違います')
    end
  end

  describe 'モデレーターログアウト' do
    it 'ログイン後にログアウトできる' do
      visit new_moderator_session_path

      fill_in 'moderator_login_id', with: moderator.login_id
      fill_in 'moderator_password', with: 'password123'
      click_button 'ログイン'

      find('.dropdown-trigger').click
      click_button 'ログアウト'

      expect(page).to have_content('ログアウトしました')
      expect(current_path).to eq(new_moderator_session_path)
    end
  end

  describe 'アクセス権限' do
    it 'ユーザーの認証情報でモデレーターとしてログインできない' do
      user = create(:user, password: 'password123', password_confirmation: 'password123')

      visit new_moderator_session_path

      fill_in 'moderator_login_id', with: user.login_id
      fill_in 'moderator_password', with: 'password123'
      click_button 'ログイン'

      expect(page).to have_content('ログインIDまたはパスワードが違います')
    end
  end
end
