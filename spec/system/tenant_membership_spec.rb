# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '所属テナント', type: :system do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:tenant) { create(:tenant, slug: 'test-tenant', name: 'テストテナント') }
  let!(:membership) { create(:tenant_membership, user: user, tenant: tenant, display_name: '元の表示名') }
  let!(:other_membership) { create(:tenant_membership, user: other_user, tenant: tenant, display_name: '他のユーザー') }

  scenario 'テナントメンバーが自分のプロフィールを正常に編集できる' do
    login_as user
    visit edit_tenant_membership_path(tenant_slug: tenant.slug)

    # 現在の表示名が表示されている
    expect(page).to have_field('表示名', with: '元の表示名')

    # 表示名を変更
    fill_in '表示名', with: '新しい表示名'
    click_button '更新'

    # 成功メッセージが表示される
    expect(page).to have_content('所属テナント情報が更新されました。')
    expect(page).to have_current_path(edit_tenant_membership_path(tenant_slug: tenant.slug))

    find('.back-button').click

    # ユーザープロフィール編集ページに遷移することを確認
    expect(page).to have_current_path(edit_user_profile_path)
  end

  scenario '空の表示名では更新できない' do
    login_as user
    visit edit_tenant_membership_path(tenant_slug: tenant.slug)

    fill_in '表示名', with: ''
    click_button '更新'

    # エラーメッセージが表示される
    expect(page).to have_content('表示名を入力してください')
  end

  scenario '未ログインユーザーは編集ページにアクセスできない' do
    visit edit_tenant_membership_path(tenant_slug: tenant.slug)

    # 403エラーページが表示される
    expect(page).to have_content('アクセスが禁止されています')
  end

  scenario 'テナントのメンバーでないユーザーは編集ページにアクセスできない' do
    non_member_user = create(:user)
    login_as non_member_user

    visit edit_tenant_membership_path(tenant_slug: tenant.slug)

    expect(page).to have_content('権限がありません')
  end

  describe 'サスペンドのテナント分離' do
    let(:tenant_suspend_a) { create(:tenant, slug: 'suspend-tenant-a', name: 'サスペンドテナントA') }
    let(:tenant_suspend_b) { create(:tenant, slug: 'suspend-tenant-b', name: 'サスペンドテナントB') }
    let(:user_suspend) { create(:user) }
    let(:other_user_suspend) { create(:user) }
    let(:membership_suspend_a) do
      create(:tenant_membership, tenant: tenant_suspend_a, user: user_suspend, display_name: 'サスペンドユーザーA')
    end
    let(:membership_suspend_b) do
      create(:tenant_membership, tenant: tenant_suspend_b, user: user_suspend, display_name: 'サスペンドユーザーB')
    end
    let(:other_membership_suspend_a) do
      create(:tenant_membership, tenant: tenant_suspend_a, user: other_user_suspend, display_name: '他のユーザーA')
    end
    let(:other_membership_suspend_b) do
      create(:tenant_membership, tenant: tenant_suspend_b, user: other_user_suspend, display_name: '他のユーザーB')
    end

    scenario 'テナントAでサスペンドされてもテナントBでは書き込みができる' do
      membership_suspend_a
      membership_suspend_b
      membership_suspend_a.suspend!(3.days.from_now)

      login_as user_suspend

      visit tenant_path(tenant_slug: tenant_suspend_a.slug)
      expect(page).not_to have_link('お題を投稿する')

      visit tenant_path(tenant_slug: tenant_suspend_b.slug)
      expect(page).to have_link('お題を投稿する')

      click_link 'お題を投稿する'
      fill_in 'タイトル', with: 'テナントBのトピック'
      click_button '登録する'

      expect(page).to have_content('お題が作成されました')
      expect(page).to have_content('テナントBのトピック')
    end

    scenario 'サスペンドされたユーザーのコメントはそのテナント内でのみ非表示になる' do
      membership_suspend_a
      membership_suspend_b
      other_membership_suspend_a
      other_membership_suspend_b

      topic_a = create(:topic, tenant: tenant_suspend_a, author: other_user_suspend)
      topic_b = create(:topic, tenant: tenant_suspend_b, author: other_user_suspend)
      create(:comment, topic: topic_a, author: user_suspend, content: 'テナントAのコメント')
      create(:comment, topic: topic_b, author: user_suspend, content: 'テナントBのコメント')

      membership_suspend_a.suspend!(3.days.from_now)

      login_as other_user_suspend

      visit tenant_topic_path(tenant_slug: tenant_suspend_a.slug, id: topic_a.id)
      expect(page).not_to have_content('テナントAのコメント')
      expect(page).to have_content('このコメントは非表示です')

      visit tenant_topic_path(tenant_slug: tenant_suspend_b.slug, id: topic_b.id)
      expect(page).to have_content('テナントBのコメント')
      expect(page).not_to have_content('このコメントは非表示です')
    end
  end
end
