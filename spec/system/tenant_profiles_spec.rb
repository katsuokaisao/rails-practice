# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'テナントプロフィール', type: :system do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:tenant) { create(:tenant, identifier: 'test-tenant', name: 'テストテナント') }
  let!(:membership) { create(:tenant_membership, user: user, tenant: tenant, display_name: '元の表示名') }
  let!(:other_membership) { create(:tenant_membership, user: other_user, tenant: tenant, display_name: '他のユーザー') }

  scenario 'テナントメンバーが自分のプロフィールを正常に編集できる' do
    login_as user
    visit tenant_users_profile_path(tenant_slug: tenant.identifier)

    # 現在の表示名が表示されている
    expect(page).to have_field('表示名', with: '元の表示名')

    # 表示名を変更
    fill_in '表示名', with: '新しい表示名'
    click_button '更新'

    # 成功メッセージが表示される
    expect(page).to have_content('テナントが更新されました')
    expect(page).to have_current_path(tenant_users_profile_path(tenant_slug: tenant.identifier))

    find('.back-button').click

    # ユーザープロフィール編集ページに遷移することを確認
    expect(page).to have_current_path(edit_user_profile_path)
  end

  scenario '空の表示名では更新できない' do
    login_as user
    visit tenant_users_profile_path(tenant_slug: tenant.identifier)

    fill_in '表示名', with: ''
    click_button '更新'

    # エラーメッセージが表示される
    expect(page).to have_content('表示名を入力してください')
  end

  scenario '未ログインユーザーは編集ページにアクセスできない' do
    visit tenant_users_profile_path(tenant_slug: tenant.identifier)

    # 403エラーページが表示される
    expect(page).to have_content('アクセスが禁止されています')
  end

  scenario 'テナントのメンバーでないユーザーは編集ページにアクセスできない' do
    non_member_user = create(:user)
    login_as non_member_user

    visit tenant_users_profile_path(tenant_slug: tenant.identifier)

    expect(page).to have_content('権限がありません')
  end
end
