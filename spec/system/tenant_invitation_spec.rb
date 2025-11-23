# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'テナント招待機能', type: :system do
  let(:tenant) { create(:tenant, slug: 'test-tenant', name: 'テストテナント') }
  let(:inviter) { create(:user) }
  let(:invited_user) { create(:user) }

  before do
    create(:tenant_membership, tenant: tenant, user: inviter, display_name: '招待者')
  end

  scenario 'テナントメンバーが新規ユーザーを招待し、招待されたユーザーが受け入れる' do
    login_as inviter
    visit new_tenant_invitation_path(tenant_slug: tenant.slug)

    fill_in '招待するユーザー', with: invited_user.id
    click_button '招待を送信'

    expect(page).to have_current_path(tenant_path(tenant_slug: tenant.slug))

    logout
    login_as invited_user

    visit my_invitations_path
    expect(page).to have_content('テストテナント')

    click_link '招待を受ける'
    expect(page).to have_content('テストテナント') # タイトルにテナント名が表示される
    fill_in '表示名', with: '新メンバー'
    click_button '参加する'

    expect(page).to have_current_path(tenant_path(tenant_slug: tenant.slug))
    expect(page).to have_content('テストテナント')
  end

  scenario '招待されたユーザーが招待を拒否する' do
    invitation = create(:tenant_invitation,
                        tenant: tenant, inviter: inviter, invited_user: invited_user,
                        status: :pending)

    login_as invited_user

    visit my_invitations_path
    expect(page).to have_content('テストテナント')

    accept_confirm do
      click_button '拒否する'
    end

    expect(page).to have_current_path(my_invitations_path)
    expect(page).not_to have_content('テストテナント')
    expect(invitation.reload.status).to eq('rejected')
  end

  scenario '招待作成時のバリデーションエラー（自分自身を招待）' do
    login_as inviter
    visit new_tenant_invitation_path(tenant_slug: tenant.slug)

    fill_in '招待するユーザー', with: inviter.id
    click_button '招待を送信'

    expect(page).to have_content('は自分自身を指定できません')
  end

  scenario '招待作成時のバリデーションエラー（既にメンバー）' do
    existing_member = create(:user)
    create(:tenant_membership, tenant: tenant, user: existing_member, display_name: '既存メンバー')

    login_as inviter
    visit new_tenant_invitation_path(tenant_slug: tenant.slug)

    fill_in '招待するユーザー', with: existing_member.id
    click_button '招待を送信'

    expect(page).to have_content('は既にメンバーです')
  end

  scenario '招待作成時のバリデーションエラー（既に招待済み）' do
    create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :pending)

    login_as inviter
    visit new_tenant_invitation_path(tenant_slug: tenant.slug)

    fill_in '招待するユーザー', with: invited_user.id
    click_button '招待を送信'

    expect(page).to have_content('には既に招待を送信しています')
  end

  scenario '招待受け入れ時のバリデーションエラー（既に存在するdisplay_name）' do
    existing_member = create(:user)
    create(:tenant_membership, tenant: tenant, user: existing_member, display_name: '既存の表示名')
    create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :pending)

    login_as invited_user
    visit my_invitations_path

    click_link '招待を受ける'
    fill_in '表示名', with: '既存の表示名'
    click_button '参加する'

    expect(page).to have_content('はこのテナント内で既に使用されています')
  end

  scenario '招待受け入れ時のバリデーションエラー（51文字のdisplay_name）' do
    create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :pending)

    login_as invited_user
    visit my_invitations_path

    click_link '招待を受ける'
    fill_in '表示名', with: 'あ' * 51
    click_button '参加する'

    expect(page).to have_content('は50文字以内で入力してください')
  end

  context '招待のテナント分離' do
    let!(:tenant_a) { create(:tenant, slug: 'tenant-a', name: 'テナントA') }
    let!(:tenant_b) { create(:tenant, slug: 'tenant-b', name: 'テナントB') }
    let!(:inviter_multi) { create(:user) }
    let!(:invited_user_multi) { create(:user) }

    before do
      create(:tenant_membership, tenant: tenant_a, user: inviter_multi, display_name: '招待者')
    end

    scenario 'テナントAからの招待を受諾してもテナントBのメンバーにはならない' do
      create(:tenant_invitation, tenant: tenant_a, inviter: inviter_multi, invited_user: invited_user_multi,
                                 status: :pending)

      login_as invited_user_multi
      visit my_invitations_path

      click_link '招待を受ける'
      fill_in '表示名', with: '新メンバー'
      click_button '参加する'

      expect(page).to have_content('テナントA')

      visit tenant_path(tenant_slug: tenant_a.slug)
      expect(page).to have_link('お題を投稿する')

      visit tenant_path(tenant_slug: tenant_b.slug)
      expect(page).not_to have_link('お題を投稿する')
    end
  end
end
