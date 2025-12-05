# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ユーザー認証', type: :system do
  let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }

  describe 'ユーザー登録' do
    it '新規ユーザーが正常に登録できる' do
      visit new_user_registration_path

      fill_in 'user_login_id', with: 'newuser'
      fill_in 'user_password', with: 'password123'
      fill_in 'user_password_confirmation', with: 'password123'

      click_button '登録'

      expect(page).to have_content('アカウント登録が完了しました')
      expect(current_path).to eq(root_path)
    end

    it 'パスワードと確認用パスワードが一致しない場合はエラーが表示される' do
      visit new_user_registration_path

      fill_in 'user_login_id', with: 'newuser'
      fill_in 'user_password', with: 'password123'
      fill_in 'user_password_confirmation', with: 'different_password'

      click_button '登録'

      expect(page).to have_content('パスワード（確認用）とパスワードの入力が一致しません')
    end

    it '既に存在するログインIDでは登録できない' do
      existing_user = create(:user, login_id: 'existing_user')

      visit new_user_registration_path

      fill_in 'user_login_id', with: existing_user.login_id
      fill_in 'user_password', with: 'password123'
      fill_in 'user_password_confirmation', with: 'password123'

      click_button '登録'

      expect(page).to have_content('ログインIDはすでに存在します')
    end
  end

  describe 'ユーザーログイン' do
    it '正しい認証情報でログインできる' do
      visit new_user_session_path

      fill_in 'user_login_id', with: user.login_id
      fill_in 'user_password', with: 'password123'
      click_button 'ログイン'

      expect(page).to have_content('ログインしました')
      expect(current_path).to eq(root_path)

      find('.dropdown-trigger').click
      expect(page).to have_button('ログアウト')
      expect(page).not_to have_link('ユーザーログイン')
      expect(page).not_to have_link('ユーザー登録')
    end

    it '間違ったパスワードではログインできない' do
      visit new_user_session_path

      fill_in 'user_login_id', with: user.login_id
      fill_in 'user_password', with: 'wrong_password'
      click_button 'ログイン'

      expect(page).to have_content('ログインIDまたはパスワードが違います')
    end
  end

  describe 'ユーザーログアウト' do
    it 'ログインボタン押下後にログアウトできる' do
      visit new_user_session_path

      fill_in 'user_login_id', with: user.login_id
      fill_in 'user_password', with: 'password123'
      click_button 'ログイン'

      find('.dropdown-trigger').click
      click_button 'ログアウト'
      expect(page).to have_content('ログアウトしました')
      expect(current_path).to eq(new_user_session_path)
    end
  end

  describe 'プロフィール変更' do
    it 'ユーザーがプロフィールを正常に更新できる' do
      login_as user
      visit edit_user_profile_path

      fill_in 'ログインID', with: 'updated_nickname'
      click_button '更新する'

      expect(page).to have_content('アカウント情報を変更しました。')
      expect(current_path).to eq(edit_user_profile_path)
    end

    it '無効なログインIDでは更新できない' do
      login_as user
      visit edit_user_profile_path

      fill_in 'ログインID', with: ''
      click_button '更新する'

      expect(page).to have_content('ログインIDを入力してください')
    end
  end

  describe 'パスワード更新' do
    it 'ユーザーがパスワードを正常に更新できる' do
      login_as user
      visit edit_user_password_path

      fill_in 'パスワード', with: 'newpassword123'
      fill_in 'パスワード（確認用）', with: 'newpassword123'
      fill_in '現在のパスワード', with: 'password123'
      click_button 'パスワードを更新'

      expect(page).to have_content('アカウント情報を変更しました。')
      expect(current_path).to eq(root_path)
    end

    it '無効なパスワードでは更新できない' do
      login_as user
      visit edit_user_password_path

      fill_in 'パスワード', with: 'short'
      fill_in 'パスワード（確認用）', with: 'short'
      fill_in '現在のパスワード', with: 'password123'
      click_button 'パスワードを更新'

      expect(page).to have_content('パスワードは8文字以上で入力してください')
    end
  end

  describe '所属テナント' do
    let(:first_tenant) { create(:tenant, slug: 'tenant-1', name: 'テナント1') }
    let(:second_tenant) { create(:tenant, slug: 'tenant-2', name: 'テナント2') }

    it 'プロフィール画面で所属テナント一覧が表示される' do
      create(:tenant_membership, user: user, tenant: first_tenant, display_name: 'ユーザー1のテナント1での表示名')
      create(:tenant_membership, user: user, tenant: second_tenant, display_name: 'ユーザー1のテナント2での表示名')

      login_as user
      visit edit_user_profile_path

      # 所属テナント情報が表示されている
      expect(page).to have_content('テナント1')
      expect(page).to have_content('ユーザー1のテナント1での表示名')
      expect(page).to have_content('テナント2')
      expect(page).to have_content('ユーザー1のテナント2での表示名')
    end

    it '所属テナントがない場合、空のメッセージが表示される' do
      login_as user
      visit edit_user_profile_path

      # 所属テナントがない旨のメッセージが表示される
      expect(page).not_to have_css('.membership-item')
    end

    it '所属テナントの編集リンクをクリックすると、テナントプロフィール編集画面に遷移する' do
      create(:tenant_membership, user: user, tenant: first_tenant, display_name: '元の表示名')

      login_as user
      visit edit_user_profile_path

      click_link '編集する'
      expect(page).to have_field('表示名', with: '元の表示名')
      expect(current_path).to eq(edit_tenant_membership_path(tenant_slug: first_tenant.slug))
    end

    it '退会したテナントはプロフィール画面の所属テナント一覧に表示されない' do
      create(:tenant_membership, user: user, tenant: first_tenant, display_name: 'アクティブメンバー')
      create(:tenant_membership, user: user, tenant: second_tenant, display_name: '退会済みメンバー',
                                 unsubscribed_at: Time.current)

      login_as user
      visit edit_user_profile_path

      expect(page).to have_content('テナント1')
      expect(page).to have_content('アクティブメンバー')

      expect(page).not_to have_content('テナント2')
      expect(page).not_to have_content('退会済みメンバー')
    end
  end
end
