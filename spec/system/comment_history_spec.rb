# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'コメント履歴', type: :system do
  let!(:tenant) { create(:tenant) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:moderator) { create(:moderator) }

  let!(:user_membership) { create(:tenant_membership, tenant: tenant, user: user, display_name: 'ユーザー1') }
  let!(:other_user_membership) { create(:tenant_membership, tenant: tenant, user: other_user, display_name: 'ユーザー2') }

  let!(:topic) { create(:topic, tenant: tenant, author: user, title: 'テストトピック') }
  let!(:comment) { create(:comment, topic: topic, author: user, content: '初回コメント') }
  let!(:other_comment) { create(:comment, topic: topic, author: other_user, content: '他のユーザーのコメント') }

  before do
    comment.update_content!('2回目の編集')
    comment.update_content!('3回目の編集')
    other_comment.update_content!('他のユーザーのコメント 2回目の編集')
    other_comment.update_content!('他のユーザーのコメント 3回目の編集')
  end

  scenario '未ログインユーザーがコメント履歴を閲覧できない' do
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_link('履歴',
                                  href: tenant_comment_histories_path(tenant_slug: tenant.identifier,
                                                                      comment_id: comment.id))
    visit tenant_comment_histories_path(tenant_slug: tenant.identifier, comment_id: comment.id)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'ログインユーザーが自分のコメント履歴を閲覧できる' do
    login_as(user)
    visit tenant_comment_histories_path(tenant_slug: tenant.identifier, comment_id: comment.id)
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
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_link('履歴',
                                  href: tenant_comment_histories_path(tenant_slug: tenant.identifier,
                                                                      comment_id: other_comment.id))
    visit tenant_comment_histories_path(tenant_slug: tenant.identifier, comment_id: other_comment.id)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'モデレーターは全てのコメント履歴を閲覧できる' do
    login_as(moderator, scope: :moderator)
    visit tenant_comment_histories_path(tenant_slug: tenant.identifier, comment_id: comment.id)
    expect(page).to have_content('コメント編集履歴')
    expect(page).to have_content('初回コメント')
    expect(page).to have_content('バージョン: 1')

    visit tenant_comment_histories_path(tenant_slug: tenant.identifier, comment_id: other_comment.id)
    expect(page).to have_content('コメント編集履歴')
    expect(page).to have_content('他のユーザーのコメント')
    expect(page).to have_content('バージョン: 1')
  end

  scenario 'コメント履歴の比較機能が正しく動作する' do
    login_as(user)
    visit tenant_comment_histories_path(tenant_slug: tenant.identifier, comment_id: comment.id)
    select '1', from: 'From:'
    select '2', from: 'To:'
    click_button '選択したバージョンを比較'
    expect(page).to have_content('コメント編集履歴の比較')
    expect(page).to have_content('バージョン: 1')
    expect(page).to have_content('バージョン: 2')
  end

  scenario '同じバージョンを比較しようとするとエラーになる' do
    login_as(user)
    visit tenant_comment_histories_path(tenant_slug: tenant.identifier, comment_id: comment.id)
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
    visit tenant_comment_histories_path(tenant_slug: tenant.identifier, comment_id: comment.id)
    expect(page).to have_content('コメント編集履歴')
    expect(page).to have_selector('.pagination')

    click_link '2'
    expect(page).to have_content('1回目の編集')

    visit compare_tenant_comment_histories_path(tenant_slug: tenant.identifier, comment_id: comment.id, page: 999)
    expect(page).to have_content('同じバージョンを選択することはできません。異なるバージョンを選択してください。')
  end
end
