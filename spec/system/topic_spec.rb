# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'トピック', type: :system do
  let!(:tenant) { create(:tenant) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:suspended_user) { create(:user, :suspended_in, tenant: tenant, display_name: '停止ユーザー') }

  let!(:user_membership) { create(:tenant_membership, tenant: tenant, user: user, display_name: 'ユーザー1') }
  let!(:other_user_membership) { create(:tenant_membership, tenant: tenant, user: other_user, display_name: 'ユーザー2') }

  let!(:topic) { create(:topic, tenant: tenant, author: user, title: 'テストトピック') }
  let!(:other_topic) { create(:topic, tenant: tenant, author: other_user, title: '他のユーザーのトピック') }
  let(:long_x_special_char_topic) { create(:topic, tenant: tenant, author: user, title: "#{'a' * 118}👉＠") }

  context '未ログインユーザー' do
    it 'トピック一覧を閲覧できる' do
      visit tenant_path(tenant_slug: tenant.slug)

      expect(page).to have_content('テストトピック')
      expect(page).to have_content('他のユーザーのトピック')
      expect(page).not_to have_link('新規トピック作成')
      expect(page).not_to have_selector('.edit-actions')
    end

    it 'トピック詳細を閲覧できる' do
      create_list(:comment, 20, :short_content, topic: topic)
      visit tenant_topic_path(tenant_slug: tenant.slug, id: topic.id)

      within('.topic-show') do
        expect(page).to have_content('テストトピック')
        expect(page).to have_content(user.display_name_for(tenant))
        expect(page).to have_content("(ID: #{user.id})")
        expect(page).to have_content("作成日: #{topic.created_at.strftime('%Y/%m/%d %H:%M')}")
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
      visit new_tenant_topic_path(tenant_slug: tenant.slug)
      expect(page).to have_content('アクセスが禁止されています。')
    end
  end

  context 'ログインユーザ' do
    scenario 'ログインユーザーが新規トピックを作成し、編集できる' do
      login_as(user)
      visit tenant_path(tenant_slug: tenant.slug)
      expect(page).to have_content('お題 一覧')
      click_link 'お題を投稿する'
      expect(page).to have_content('お題 新規作成')
      fill_in 'タイトル', with: '新しいトピック'
      click_button '登録する'
      expect(page).to have_content('お題が作成されました。')
      within('.topic-show') do
        expect(page).to have_content('新しいトピック')
        expect(page).to have_content(user.display_name_for(tenant))
        expect(page).to have_content("(ID: #{user.id})")
        expect(page).to have_content("作成日: #{topic.created_at.strftime('%Y/%m/%d %H:%M')}")
      end
    end

    scenario 'ログインユーザーが自分のトピックを編集できる' do
      login_as(user)
      visit tenant_topic_path(tenant_slug: tenant.slug, id: topic.id)
      expect(page).to have_link('edit')
      click_link 'edit'
      expect(page).to have_content('お題 編集')
      fill_in 'タイトル', with: '編集されたトピック'
      click_button '更新する'
      expect(page).to have_content('お題が更新されました。')
      within('.topic-show') do
        expect(page).to have_content('編集されたトピック')
        expect(page).to have_content(user.display_name_for(tenant))
        expect(page).to have_content("(ID: #{user.id})")
        expect(page).to have_content("作成日: #{topic.created_at.strftime('%Y/%m/%d %H:%M')}")
      end
    end

    scenario 'ログインユーザーは他のユーザーのトピックを編集できない' do
      login_as(user)
      visit tenant_topic_path(tenant_slug: tenant.slug, id: other_topic.id)
      expect(page).not_to have_link('edit')
      visit edit_tenant_topic_path(tenant_slug: tenant.slug, id: other_topic.id)
      expect(page).to have_content('アクセスが禁止されています。')
    end

    scenario 'トピック作成時の入力バリデーションが機能する' do
      login_as(user)
      visit new_tenant_topic_path(tenant_slug: tenant.slug)

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
      visit edit_tenant_topic_path(tenant_slug: tenant.slug, id: topic.id)

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
      visit tenant_path(tenant_slug: tenant.slug)
      expect(page).not_to have_link('お題を投稿する')
      visit new_tenant_topic_path(tenant_slug: tenant.slug)
      expect(page).to have_content('アクセスが禁止されています。')
    end

    it '停止されたユーザーは自分のトピックを編集できない' do
      login_as(suspended_user)
      visit tenant_topic_path(tenant_slug: tenant.slug, id: topic.id)
      expect(page).not_to have_link('edit')
      visit edit_tenant_topic_path(tenant_slug: tenant.slug, id: topic.id)
      expect(page).to have_content('アクセスが禁止されています。')
    end
  end

  context 'ページネーション' do
    it 'トピック一覧のページネーションが機能する' do
      create_list(:topic, 30, tenant: tenant, author: user)

      topic = tenant.topics.order(created_at: :desc).last
      visit tenant_path(tenant_slug: tenant.slug)
      expect(page).to have_selector('.pagination')
      click_link '2'
      expect(page).to have_content(topic.title)
      expect(page).to have_content(topic.author.display_name_for(tenant))
      expect(page).to have_content("(ID: #{topic.author.id})")
      expect(page).to have_content("作成日: #{topic.created_at.strftime('%Y/%m/%d %H:%M')}")
      visit tenant_path(tenant_slug: tenant.slug, page: 999)
      expect(page).to have_content('範囲外のリクエストです。')
    end

    it 'トピック詳細ページのコメントページネーションが機能する' do
      create_list(:comment, 30, :short_content, topic: topic)

      visit tenant_topic_path(tenant_slug: tenant.slug, id: topic.id)
      expect(page).to have_selector('.pagination')
      click_link '2'
      comment = topic.comments.order(created_at: :desc).last
      expect(page).to have_content(comment.content)
      expect(page).to have_content(comment.author.display_name_for(tenant))
      expect(page).to have_content("作成日: #{comment.created_at.strftime('%Y/%m/%d %H:%M')}")
      visit tenant_topic_path(tenant_slug: tenant.slug, id: topic.id, page: 999)
      expect(page).to have_content('範囲外のリクエストです。')
    end
  end

  it '長いタイトルや特殊文字を含むトピックが正しく表示される' do
    long_x_special_char_topic

    visit tenant_path(tenant_slug: tenant.slug)
    expect(page).to have_content(long_x_special_char_topic.title)

    visit tenant_topic_path(tenant_slug: tenant.slug, id: long_x_special_char_topic.id)
    expect(page).to have_content(long_x_special_char_topic.title)
  end

  context 'マルチテナントのデータ分離' do
    let!(:tenant_a) { create(:tenant, slug: 'tenant-a', name: 'テナントA') }
    let!(:tenant_b) { create(:tenant, slug: 'tenant-b', name: 'テナントB') }
    let!(:user_multi) { create(:user) }
    let!(:membership_a) { create(:tenant_membership, tenant: tenant_a, user: user_multi, display_name: 'ユーザーA') }
    let!(:membership_b) { create(:tenant_membership, tenant: tenant_b, user: user_multi, display_name: 'ユーザーB') }
    let!(:topic_a) { create(:topic, tenant: tenant_a, author: user_multi, title: 'テナントAのトピック') }
    let!(:topic_b) { create(:topic, tenant: tenant_b, author: user_multi, title: 'テナントBのトピック') }

    scenario 'テナントAのトピックがテナントBの一覧に表示されない' do
      login_as(user_multi)

      visit tenant_path(tenant_slug: tenant_a.slug)
      expect(page).to have_content('テナントAのトピック')
      expect(page).not_to have_content('テナントBのトピック')

      visit tenant_path(tenant_slug: tenant_b.slug)
      expect(page).to have_content('テナントBのトピック')
      expect(page).not_to have_content('テナントAのトピック')
    end

    scenario 'テナントAのトピックIDをテナントBのURLで指定してもアクセスできない' do
      login_as(user_multi)

      visit tenant_topic_path(tenant_slug: tenant_b.slug, id: topic_a.id)
      expect(page).to have_content('ActiveRecord::RecordNotFound')
    end

    scenario '同じユーザーでもテナントごとに異なる表示名が使用される' do
      login_as(user_multi)

      visit tenant_topic_path(tenant_slug: tenant_a.slug, id: topic_a.id)
      within('.topic-show') do
        expect(page).to have_content('ユーザーA')
        expect(page).not_to have_content('ユーザーB')
      end

      visit tenant_topic_path(tenant_slug: tenant_b.slug, id: topic_b.id)
      within('.topic-show') do
        expect(page).to have_content('ユーザーB')
        expect(page).not_to have_content('ユーザーA')
      end
    end
  end

  context '非所属テナントでのアクセス制限' do
    let!(:member_tenant) { create(:tenant, slug: 'member-tenant', name: 'メンバーテナント') }
    let!(:non_member_tenant) { create(:tenant, slug: 'non-member-tenant', name: '非メンバーテナント') }
    let!(:multi_user) { create(:user) }
    let!(:member_membership) do
      create(:tenant_membership, tenant: member_tenant, user: multi_user, display_name: 'メンバー')
    end

    scenario '非所属テナントではトピック作成ボタンが表示されず、作成もできない' do
      login_as(multi_user)

      visit tenant_path(tenant_slug: non_member_tenant.slug)
      expect(page).not_to have_link('お題を投稿する')

      visit new_tenant_topic_path(tenant_slug: non_member_tenant.slug)
      expect(page).to have_content('アクセスが禁止されています')

      visit tenant_path(tenant_slug: member_tenant.slug)
      expect(page).to have_link('お題を投稿する')
    end
  end

  context 'ロックされたトピック' do
    let!(:locked_topic) { create(:topic, :locked, tenant: tenant, author: user, title: 'ロックされたトピック') }

    scenario 'ロックされたトピックは編集できない' do
      login_as(user)

      visit tenant_topic_path(tenant_slug: tenant.slug, id: locked_topic.id)
      expect(page).not_to have_link('edit')

      visit edit_tenant_topic_path(tenant_slug: tenant.slug, id: locked_topic.id)
      expect(page).to have_content('アクセスが禁止されています。')
    end

    scenario 'ロックされたトピックは一覧でロックアイコンが表示される' do
      visit tenant_path(tenant_slug: tenant.slug)

      expect(page).to have_content('🔒')
      expect(page).to have_content('ロック済み')
    end
  end
end
