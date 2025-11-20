# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BAN理由管理', type: :system do
  let!(:tenant) { create(:tenant) }
  let!(:user) { create(:user) }
  let!(:moderator) { create(:moderator, tenant: tenant) }
  let!(:user_membership) { create(:tenant_membership, tenant: tenant, user: user, display_name: 'ユーザー1') }

  scenario '未ログインユーザーがBAN理由管理ページにアクセスできない' do
    visit tenant_ban_reasons_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario '一般ユーザーがBAN理由管理ページにアクセスできない' do
    login_as(user)
    visit tenant_ban_reasons_path(tenant_slug: tenant.identifier)
    expect(page).to have_content('アクセスが禁止されています。')
  end

  scenario 'モデレーターがBAN理由一覧を閲覧できる' do
    create(:ban_reason, :system_reason, tenant: tenant, active: true)
    create(:ban_reason, tenant: tenant, name: 'カスタム理由1', description: 'カスタム理由の説明', active: true)

    login_as(moderator, scope: :moderator)
    visit tenant_ban_reasons_path(tenant_slug: tenant.identifier)

    expect(page).to have_content('BAN理由 一覧')

    within('.ban-reasons-section', text: 'システムBAN理由') do
      expect(page).to have_content('スパム')
    end

    within('.ban-reasons-section', text: 'カスタムBAN理由') do
      expect(page).to have_content('カスタム理由1')
      expect(page).to have_content('カスタム理由の説明')
      expect(page).to have_content('有効')
      expect(page).to have_link('編集する')
      expect(page).to have_button('削除')
    end
  end

  scenario 'モデレーターがカスタムBAN理由を作成できる' do
    login_as(moderator, scope: :moderator)
    visit tenant_ban_reasons_path(tenant_slug: tenant.identifier)

    click_link '新規作成'
    expect(page).to have_content('BAN理由 新規作成')

    fill_in 'ban_reason[name]', with: '新しいカスタム理由'
    fill_in 'ban_reason[description]', with: '新しいカスタム理由の説明'
    check 'ban_reason[active]'

    click_button '登録する'
    expect(page).to have_content('BAN理由が作成されました。')
    expect(page).to have_content('新しいカスタム理由')
    expect(page).to have_content('新しいカスタム理由の説明')
  end

  scenario 'モデレーターがカスタムBAN理由を編集できる' do
    create(:ban_reason, tenant: tenant, name: 'カスタム理由1', description: '元の説明', active: true)

    login_as(moderator, scope: :moderator)
    visit tenant_ban_reasons_path(tenant_slug: tenant.identifier)

    within('.ban-reasons-section', text: 'カスタムBAN理由') do
      click_link '編集する'
    end

    expect(page).to have_content('BAN理由 編集')

    fill_in 'ban_reason[name]', with: '更新されたカスタム理由'
    fill_in 'ban_reason[description]', with: '更新された説明'
    uncheck 'ban_reason[active]'

    click_button '更新する'
    expect(page).to have_content('BAN理由が更新されました。')
    expect(page).to have_content('更新されたカスタム理由')
    expect(page).to have_content('更新された説明')
    expect(page).to have_content('無効')
  end

  scenario 'モデレーターがシステムBAN理由を編集できる（activeのみ）' do
    create(:ban_reason, :system_reason, tenant: tenant, active: true)

    login_as(moderator, scope: :moderator)
    visit tenant_ban_reasons_path(tenant_slug: tenant.identifier)

    within('.ban-reasons-section', text: 'システムBAN理由') do
      first('a', text: '編集する').click
    end

    expect(page).to have_content('BAN理由 編集')
    expect(page).to have_content('システムBAN理由は有効/無効の切り替えのみ可能です')

    expect(page).to have_field('ban_reason[name]', disabled: false, readonly: true)
    expect(page).to have_field('ban_reason[description]', disabled: false, readonly: true)

    uncheck 'ban_reason[active]'
    click_button '更新する'

    expect(page).to have_content('BAN理由が更新されました。')
    within('.ban-reasons-section', text: 'システムBAN理由') do
      expect(page).to have_content('無効')
    end
  end

  scenario 'モデレーターがカスタムBAN理由を削除できる' do
    create(:ban_reason, tenant: tenant, name: '削除対象理由', description: '削除される理由', active: true)

    login_as(moderator, scope: :moderator)
    visit tenant_ban_reasons_path(tenant_slug: tenant.identifier)

    within('.ban-reasons-section', text: 'カスタムBAN理由') do
      expect(page).to have_content('削除対象理由')
      page.accept_confirm do
        click_button '削除'
      end
    end

    expect(page).to have_content('BAN理由が削除されました。')
    expect(page).not_to have_content('削除対象理由')
  end

  scenario 'モデレーターがシステムBAN理由を削除できない' do
    create(:ban_reason, :system_reason, tenant: tenant, active: true)

    login_as(moderator, scope: :moderator)
    visit tenant_ban_reasons_path(tenant_slug: tenant.identifier)

    within('.ban-reasons-section', text: 'システムBAN理由') do
      expect(page).not_to have_button('削除')
    end
  end

  scenario 'バリデーションが機能する' do
    login_as(moderator, scope: :moderator)
    visit tenant_ban_reasons_path(tenant_slug: tenant.identifier)

    click_link '新規作成'
    expect(page).to have_content('BAN理由 新規作成')

    # 名前を空にして送信
    fill_in 'ban_reason[name]', with: ''
    fill_in 'ban_reason[description]', with: 'テスト説明'

    click_button '登録する'
    expect(page).to have_content('理由名を入力してください')
  end

  scenario '重複する名前のBAN理由を作成できない' do
    create(:ban_reason, tenant: tenant, name: '既存の理由', description: '既存の説明', active: true)

    login_as(moderator, scope: :moderator)
    visit tenant_ban_reasons_path(tenant_slug: tenant.identifier)

    click_link '新規作成'
    expect(page).to have_content('BAN理由 新規作成')

    fill_in 'ban_reason[name]', with: '既存の理由'
    fill_in 'ban_reason[description]', with: '新しい説明'

    click_button '登録する'
    expect(page).to have_content('理由名はすでに存在します')
  end

  context 'マルチテナントのデータ分離' do
    let!(:tenant_a) { create(:tenant, identifier: 'tenant-a') }
    let!(:tenant_b) { create(:tenant, identifier: 'tenant-b') }
    let!(:moderator_a) { create(:moderator, tenant: tenant_a) }
    let!(:moderator_b) { create(:moderator, tenant: tenant_b) }
    let!(:ban_reason_a) { create(:ban_reason, tenant: tenant_a, name: 'テナントAの理由', description: 'テナントAの説明') }
    let!(:ban_reason_b) { create(:ban_reason, tenant: tenant_b, name: 'テナントBの理由', description: 'テナントBの説明') }

    scenario 'テナントAのBAN理由がテナントBの一覧に表示されない' do
      login_as(moderator_b, scope: :moderator)

      visit tenant_ban_reasons_path(tenant_slug: tenant_b.identifier)
      expect(page).to have_content('テナントBの理由')
      expect(page).not_to have_content('テナントAの理由')
    end

    scenario 'モデレーターAはテナントBのBAN理由管理にアクセスできない' do
      login_as(moderator_a, scope: :moderator)

      visit tenant_ban_reasons_path(tenant_slug: tenant_b.identifier)
      expect(page).to have_content('アクセスが禁止されています')
    end
  end
end
