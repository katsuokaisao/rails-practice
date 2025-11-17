# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'テナント設定', type: :system do
  include ActiveJob::TestHelper

  let(:tenant) do
    create(:tenant,
           identifier: 'test-tenant',
           name: 'テストテナント',
           unsubscribed_user_comment_policy: :keep_visible,
           unsubscribed_user_topic_policy: :keep_visible)
  end
  let(:moderator) { create(:moderator, tenant: tenant) }
  let(:user) { create(:user) }
  let!(:membership) do
    create(:tenant_membership, user: user, tenant: tenant, display_name: 'テストユーザー', unsubscribed_at: Time.current)
  end

  before do
    login_as moderator, scope: :moderator
  end

  describe 'テナント設定画面へのアクセス' do
    scenario 'モデレーターがテナント設定画面にアクセスできる' do
      visit edit_admin_tenant_path(tenant)

      expect(page).to have_content('テナント設定')
      expect(page).to have_select('tenant_unsubscribed_user_comment_policy')
      expect(page).to have_select('tenant_unsubscribed_user_topic_policy')
    end

    scenario 'テナント設定画面に現在のポリシーが表示される' do
      tenant_with_policies = create(:tenant,
                                    identifier: 'policy-test-tenant',
                                    name: 'ポリシーテストテナント',
                                    unsubscribed_user_comment_policy: :hide_content,
                                    unsubscribed_user_topic_policy: :lock)
      moderator = create(:moderator, tenant: tenant_with_policies)
      login_as moderator, scope: :moderator

      visit edit_admin_tenant_path(tenant_with_policies)

      expect(page).to have_select('tenant_unsubscribed_user_comment_policy', selected: '内容非表示')
      expect(page).to have_select('tenant_unsubscribed_user_topic_policy', selected: 'ロック')
    end
  end

  describe 'コメントポリシーの変更' do
    let!(:topic) { create(:topic, tenant: tenant, author: user, title: 'テストトピック') }
    let!(:comment) { create(:comment, topic: topic, author: user, content: 'テストコメント') }

    scenario 'モデレーターがコメントポリシーを変更できる' do
      visit edit_admin_tenant_path(tenant)

      select '内容非表示', from: 'tenant_unsubscribed_user_comment_policy'
      click_button '更新する'

      expect(page).to have_content('テナント設定を更新しました')
      expect(tenant.reload.unsubscribed_user_comment_policy).to eq('hide_content')
    end

    scenario 'コメントポリシーを「完全削除」に変更すると既存コメントが削除される' do
      visit edit_admin_tenant_path(tenant)

      select '完全削除', from: 'tenant_unsubscribed_user_comment_policy'

      click_button '更新する'

      expect(page).to have_content('テナント設定を更新しました')

      visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)

      expect(page).not_to have_content('テストコメント')
      expect(Comment.exists?(comment.id)).to be false
    end
  end

  describe 'トピックポリシーの変更' do
    let!(:topic) { create(:topic, tenant: tenant, author: user, title: 'テストトピック') }

    scenario 'モデレーターがトピックポリシーを変更できる' do
      visit edit_admin_tenant_path(tenant)

      select 'ロック', from: 'tenant_unsubscribed_user_topic_policy'
      click_button '更新する'

      expect(page).to have_content('テナント設定を更新しました')
      expect(tenant.reload.unsubscribed_user_topic_policy).to eq('lock')
    end

    scenario 'トピックポリシーを「ロック」に変更すると既存トピックがロックされる' do
      visit edit_admin_tenant_path(tenant)

      select 'ロック', from: 'tenant_unsubscribed_user_topic_policy'

      click_button '更新する'

      expect(page).to have_content('テナント設定を更新しました')

      visit tenant_path(tenant_slug: tenant.identifier)

      expect(page).to have_content('🔒')
      expect(page).to have_content('ロック済み')
      expect(topic.reload.locked?).to be true
    end

    scenario 'トピックポリシーを「完全削除」に変更すると既存トピックが削除される' do
      visit edit_admin_tenant_path(tenant)

      select '完全削除', from: 'tenant_unsubscribed_user_topic_policy'

      click_button '更新する'

      expect(page).to have_content('テナント設定を更新しました')

      visit tenant_path(tenant_slug: tenant.identifier)

      expect(page).not_to have_content('テストトピック')
      expect(Topic.exists?(topic.id)).to be false
    end

    scenario 'トピックポリシーを「表示維持」に変更するとロックが解除される' do
      visit edit_admin_tenant_path(tenant)

      select 'ロック', from: 'tenant_unsubscribed_user_topic_policy'

      click_button '更新する'

      expect(page).to have_content('テナント設定を更新しました')

      visit tenant_path(tenant_slug: tenant.identifier)
      expect(page).to have_content('🔒')
      expect(topic.reload.locked?).to be true

      visit edit_admin_tenant_path(tenant)

      select '表示維持', from: 'tenant_unsubscribed_user_topic_policy'

      click_button '更新する'

      expect(page).to have_content('テナント設定を更新しました')

      visit tenant_path(tenant_slug: tenant.identifier)
      expect(page).not_to have_content('🔒 ロック済み')
      expect(topic.reload.locked?).to be false
    end
  end

  describe '複数ポリシーの同時変更' do
    let!(:topic) { create(:topic, tenant: tenant, author: user, title: 'テストトピック') }
    let!(:comment) { create(:comment, topic: topic, author: user, content: 'テストコメント') }

    scenario 'コメントポリシーとトピックポリシーを同時に変更できる' do
      visit edit_admin_tenant_path(tenant)

      select '完全削除', from: 'tenant_unsubscribed_user_comment_policy'
      select 'ロック', from: 'tenant_unsubscribed_user_topic_policy'

      click_button '更新する'

      expect(page).to have_content('テナント設定を更新しました')

      visit tenant_path(tenant_slug: tenant.identifier)

      expect(page).to have_content('🔒')
      expect(topic.reload.locked?).to be true

      visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
      expect(page).not_to have_content('テストコメント')
      expect(Comment.exists?(comment.id)).to be false
    end
  end

  describe 'キャンセル操作' do
    scenario 'キャンセルボタンをクリックするとテナント詳細ページに戻る' do
      visit edit_admin_tenant_path(tenant)

      click_link 'キャンセル'

      expect(page).to have_current_path(tenant_path(tenant_slug: tenant.identifier))
    end

    scenario 'キャンセル時はポリシーが変更されない' do
      original_comment_policy = tenant.unsubscribed_user_comment_policy
      original_topic_policy = tenant.unsubscribed_user_topic_policy

      visit edit_admin_tenant_path(tenant)

      select '内容非表示', from: 'tenant_unsubscribed_user_comment_policy'
      select 'ロック', from: 'tenant_unsubscribed_user_topic_policy'
      click_link 'キャンセル'

      tenant.reload
      expect(tenant.unsubscribed_user_comment_policy).to eq(original_comment_policy)
      expect(tenant.unsubscribed_user_topic_policy).to eq(original_topic_policy)
    end
  end

  describe 'アクセス権限' do
    scenario 'ログインしていないユーザーはアクセスできない' do
      logout(:moderator)

      visit edit_admin_tenant_path(tenant)

      expect(page).to have_content('ログインしてください')
    end

    scenario '一般ユーザーはアクセスできない' do
      logout(:moderator)
      login_as user

      visit edit_admin_tenant_path(tenant)

      expect(page).to have_content('アクセスが禁止されています')
    end

    scenario '他のテナントのモデレーターはアクセスできない' do
      other_tenant = create(:tenant)
      other_moderator = create(:moderator, tenant: other_tenant)

      logout(:moderator)
      login_as other_moderator, scope: :moderator

      visit edit_admin_tenant_path(tenant)

      expect(page).to have_content('権限がありません')
    end
  end

  describe 'ポリシー変更の影響範囲' do
    let(:other_tenant) { create(:tenant, identifier: 'other-tenant', name: '他のテナント') }
    let(:other_user) { create(:user) }
    let!(:other_membership) { create(:tenant_membership, user: other_user, tenant: other_tenant) }
    let!(:other_topic) { create(:topic, tenant: other_tenant, author: other_user, title: '他のテナントのトピック') }
    let!(:other_comment) { create(:comment, topic: other_topic, author: other_user, content: '他のテナントのコメント') }

    scenario 'ポリシー変更は他のテナントに影響しない' do
      visit edit_admin_tenant_path(tenant)

      select '完全削除', from: 'tenant_unsubscribed_user_comment_policy'
      select 'ロック', from: 'tenant_unsubscribed_user_topic_policy'

      click_button '更新する'

      expect(page).to have_content('テナント設定を更新しました')

      logout(:moderator)
      other_moderator = create(:moderator, tenant: other_tenant)
      login_as other_moderator, scope: :moderator

      visit tenant_path(tenant_slug: other_tenant.identifier)

      expect(page).not_to have_content('🔒 ロック済み')
      expect(other_topic.reload.locked?).to be false

      visit tenant_topic_path(tenant_slug: other_tenant.identifier, id: other_topic.id)

      expect(page).to have_content('他のテナントのコメント')
      expect(Comment.exists?(other_comment.id)).to be true
    end
  end
end
