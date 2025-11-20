# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'コメント', type: :system do
  let!(:tenant) { create(:tenant) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:suspended_user) { create(:user, :suspended_in, tenant: tenant, display_name: '停止ユーザー') }
  let!(:moderator) { create(:moderator, tenant: tenant) }

  let!(:user_membership) { create(:tenant_membership, tenant: tenant, user: user, display_name: 'ユーザー1') }
  let!(:other_user_membership) { create(:tenant_membership, tenant: tenant, user: other_user, display_name: 'ユーザー2') }

  let!(:topic) { create(:topic, tenant: tenant, author: user, title: 'テストトピック') }
  let!(:suspended_user_topic) do
    create(:topic, tenant: tenant, author: suspended_user, title: '停止ユーザーのトピック')
  end
  let!(:comment) { create(:comment, topic: topic, author: user, content: 'テストコメント') }
  let!(:other_comment) { create(:comment, topic: topic, author: other_user, content: '他のユーザーのコメント') }

  scenario '未ログインユーザーがコメントを投稿できない' do
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_content('投稿する')
  end

  scenario '未ログインユーザーはコメントを編集できない' do
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_link('編集',
                                  href: edit_tenant_topic_comment_path(tenant_slug: tenant.identifier,
                                                                       topic_id: comment.topic.id, id: comment.id))
    visit edit_tenant_topic_comment_path(tenant_slug: tenant.identifier, topic_id: comment.topic.id, id: comment.id)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'ログインユーザーがコメントを投稿できる' do
    login_as(user)
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('コメントを投稿する')
    fill_in 'コメント', with: '新しいコメント'
    click_button '投稿する'
    expect(page).to have_content('コメントが投稿されました。')
    expect(page).to have_content('新しいコメント')
  end

  scenario 'ログインユーザーが自分のコメントを編集できる' do
    login_as(user)
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    click_link '編集',
               href: edit_tenant_topic_comment_path(tenant_slug: tenant.identifier,
                                                    topic_id: comment.topic.id, id: comment.id)
    expect(page).to have_content('編集')
    sleep(1)
    fill_in 'コメント内容', with: '変更後のコメント'
    click_button '更新する'
    expect(page).to have_content('コメントが更新されました。')
    expect(page).to have_content('コメント編集履歴')
    expect(page).to have_content('変更後のコメント')
  end

  scenario 'ログインユーザーは他のユーザーのコメントを編集できない' do
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_link('edit',
                                  href: edit_tenant_topic_comment_path(tenant_slug: tenant.identifier,
                                                                       topic_id: other_comment.topic.id,
                                                                       id: other_comment.id))
    visit edit_tenant_topic_comment_path(tenant_slug: tenant.identifier,
                                         topic_id: other_comment.topic.id, id: other_comment.id)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'コメント投稿時の入力バリデーションが機能する' do
    login_as(user)
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('コメントを投稿する')

    fill_in 'コメント', with: ''
    click_button '投稿する'
    expect(page).to have_content('コメント内容を入力してください')

    fill_in 'コメント', with: 'a' * 5001
    click_button '投稿する'
    expect(page).to have_content('コメント内容は5000文字以内で入力してください')

    fill_in 'コメント', with: '<script>alert("XSS")</script>'
    click_button '投稿する'
    expect(page).to have_content('alert("XSS")')
  end

  scenario 'コメント編集時の入力バリデーションが機能する' do
    login_as(user)
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    click_link '編集',
               href: edit_tenant_topic_comment_path(tenant_slug: tenant.identifier,
                                                    topic_id: comment.topic.id, id: comment.id)
    expect(page).to have_content('編集')

    sleep(1)
    fill_in 'コメント内容', with: ''
    click_button '更新する'
    expect(page).to have_content('コメント内容を入力してください')

    fill_in 'コメント内容', with: 'a' * 5001
    click_button '更新する'
    expect(page).to have_content('コメント内容は5000文字以内で入力してください')

    fill_in 'コメント内容', with: '<script>alert("XSS")</script>'
    click_button '更新する'
    expect(page).to have_content('alert("XSS")')
  end

  scenario '停止されたユーザーはコメントを投稿できない' do
    login_as(suspended_user)
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_content('コメントを投稿する')
  end

  scenario '停止されたユーザーは自分のコメントを編集できない' do
    login_as(suspended_user)
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: suspended_user_topic.id)
    expect(page).not_to have_link('edit',
                                  href: edit_tenant_topic_comment_path(tenant_slug: tenant.identifier,
                                                                       topic_id: comment.topic.id, id: comment.id))
    visit edit_tenant_topic_comment_path(tenant_slug: tenant.identifier, topic_id: comment.topic.id, id: comment.id)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario '長い文字と特殊文字を含むコメントが正しく表示される' do
    create(:comment, topic: topic, author: user, content: "#{'a' * 4998}👉＠")
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content("#{'a' * 4998}👉＠")
  end

  scenario 'コメントを複数回編集した後も公開画面では常に最新版のみが表示されることの確認' do
    login_as(user)
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('テストコメント')

    click_link '編集',
               href: edit_tenant_topic_comment_path(tenant_slug: tenant.identifier, topic_id: topic.id, id: comment.id)
    expect(page).to have_content('編集')
    sleep(1)
    fill_in 'コメント', with: '1回目の編集'
    click_button '更新する'
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('1回目の編集')

    visit edit_tenant_topic_comment_path(tenant_slug: tenant.identifier, topic_id: topic.id, id: comment.id)
    fill_in 'コメント', with: '2回目の編集'
    click_button '更新する'
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_content('1回目の編集')
    expect(page).to have_content('2回目の編集')

    visit edit_tenant_topic_comment_path(tenant_slug: tenant.identifier, topic_id: topic.id, id: comment.id)
    fill_in 'コメント', with: '3回目の編集（最新版）'
    click_button '更新する'
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('3回目の編集（最新版）')
    expect(page).not_to have_content('1回目の編集')
    expect(page).not_to have_content('2回目の編集')

    visit tenant_comment_histories_path(tenant_slug: tenant.identifier, comment_id: comment.id)
    expect(page).to have_content('コメント編集履歴')
    expect(page).to have_content('1回目の編集')
    expect(page).to have_content('2回目の編集')
    expect(page).to have_content('3回目の編集（最新版）')
  end

  scenario 'ユーザーを停止が解除された後のコメント表示状態の確認' do
    create(:report, :for_user, tenant: tenant, reportable: user, reason_text: '嫌がらせユーザーです')
    login_as(moderator, scope: :moderator)
    visit tenant_reports_path(tenant_slug: tenant.identifier)

    expect(page).to have_content('通報 一覧')
    click_link 'ユーザー通報'
    expect(page).to have_css('li.active > a', text: 'ユーザー通報')
    expect(page).to have_content('通報 一覧')

    click_link '審査'
    expect(page).to have_content('審査')

    select 'ユーザーを停止', from: '審査種別'
    fill_in 'メモ', with: 'テスト用に停止'
    click_button '1日'

    accept_confirm do
      click_button '確定'
    end
    expect(page).to have_content('審査が作成されました。')
    logout

    login_as(user)
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_content('通報対象コメント')
    expect(page).to have_content('規約違反の可能性があるため、アカウントが停止されています。')

    user.reload.enforce_release_suspension!(tenant)

    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('テストコメント')
  end

  scenario '停止中ユーザーの非表示コメントの状態確認（二重制約の確認）' do
    create(:report, :for_comment,
           tenant: tenant, reportable: comment, reason_text: '嫌がらせコメントです')

    login_as(moderator, scope: :moderator)
    visit tenant_reports_path(tenant_slug: tenant.identifier)

    click_link '審査'
    expect(page).to have_content('審査')

    select 'コメントを非表示', from: '審査種別'
    fill_in 'メモ', with: 'テスト用に非表示'
    accept_confirm do
      click_button '確定'
    end
    expect(page).to have_content('審査が作成されました。')

    create(:report, :for_user, tenant: tenant, reportable: user, reason_text: '嫌がらせユーザーです')

    visit tenant_reports_path(tenant_slug: tenant.identifier)
    click_link 'ユーザー通報'

    expect(page).to have_css('li.active > a', text: 'ユーザー通報')
    click_link '審査'
    expect(page).to have_content('審査')

    select 'ユーザーを停止', from: '審査'
    fill_in 'メモ', with: 'テスト用に停止'
    click_button '1日'
    accept_confirm do
      click_button '確定'
    end
    expect(page).to have_content('審査が作成されました。')

    logout
    login_as(other_user)

    # アカウント停止中かつコメント非表示のため、コメントの内容が非表示になっていることを確認
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).not_to have_content('通報対象コメント')
    expect(page).to have_content('このコメントは非表示です。')

    user.reload.enforce_release_suspension!(tenant)
    expect(user.reload.suspended?(tenant)).to be false

    # アカウントの停止が解除されたが、コメント非表示は継続されていることを確認
    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('このコメントは非表示です。')
  end

  scenario 'コメント数が正しく表示されることの確認' do
    topic = create(:topic, tenant: tenant, author: user, title: 'テストトピック1')

    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('コメント数: 0件')

    Comment.create!(
      topic: topic,
      author: user,
      content: 'テストコメント1'
    )

    visit tenant_topic_path(tenant_slug: tenant.identifier, id: topic.id)
    expect(page).to have_content('コメント数: 1件')
  end

  context 'マルチテナントのデータ分離' do
    let!(:tenant_a) { create(:tenant, identifier: 'tenant-a') }
    let!(:tenant_b) { create(:tenant, identifier: 'tenant-b') }
    let!(:user_multi) { create(:user) }
    let!(:membership_a) { create(:tenant_membership, tenant: tenant_a, user: user_multi, display_name: 'ユーザーA') }
    let!(:membership_b) { create(:tenant_membership, tenant: tenant_b, user: user_multi, display_name: 'ユーザーB') }
    let!(:topic_a) { create(:topic, tenant: tenant_a, author: user_multi) }
    let!(:topic_b) { create(:topic, tenant: tenant_b, author: user_multi) }
    let!(:comment_a) { create(:comment, topic: topic_a, author: user_multi, content: 'テナントAのコメント') }
    let!(:comment_b) { create(:comment, topic: topic_b, author: user_multi, content: 'テナントBのコメント') }

    scenario 'テナントAのコメントがテナントBのトピックに表示されない' do
      login_as(user_multi)

      visit tenant_topic_path(tenant_slug: tenant_a.identifier, id: topic_a.id)
      expect(page).to have_content('テナントAのコメント')
      expect(page).not_to have_content('テナントBのコメント')

      visit tenant_topic_path(tenant_slug: tenant_b.identifier, id: topic_b.id)
      expect(page).to have_content('テナントBのコメント')
      expect(page).not_to have_content('テナントAのコメント')
    end
  end

  context '非所属テナントでのアクセス制限' do
    let!(:member_tenant) { create(:tenant, identifier: 'member-tenant') }
    let!(:non_member_tenant) { create(:tenant, identifier: 'non-member-tenant') }
    let!(:multi_user) { create(:user) }
    let!(:other_user_multi) { create(:user) }
    let!(:member_membership) do
      create(:tenant_membership, tenant: member_tenant, user: multi_user, display_name: 'メンバー')
    end
    let!(:other_membership) do
      create(:tenant_membership, tenant: non_member_tenant, user: other_user_multi, display_name: '他のユーザー')
    end
    let!(:non_member_topic) { create(:topic, tenant: non_member_tenant, author: other_user_multi) }

    scenario '非所属テナントではコメント投稿フォームが表示されず、投稿もできない' do
      login_as(multi_user)

      visit tenant_topic_path(tenant_slug: non_member_tenant.identifier, id: non_member_topic.id)
      expect(page).not_to have_content('コメントを投稿する')
    end
  end
end
