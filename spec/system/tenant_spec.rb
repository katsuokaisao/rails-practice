# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'テナント', type: :system do
  let!(:user) { create(:user) }
  let!(:moderator) { create(:moderator) }

  describe '全てのユーザーがテナント一覧から詳細ページへの一連の閲覧ができる' do
    [
      { role: '未ログインユーザー', login: :none },
      { role: 'ログインユーザー', login: :user },
      { role: 'モデレーター', login: :moderator }
    ].each do |test_case|
      scenario "#{test_case[:role]}がテナント一覧から詳細ページへの一連の閲覧ができる" do
        create(:tenant, name: '社内フォーラム', identifier: 'company-forum',
                        description: '社員向けの情報共有・質問・議論のための掲示板です。')
        create(:tenant, name: 'アイドルファンコミュニティ', identifier: 'idol-community',
                        description: 'アイドルファンが集まるコミュニティ掲示板です。')
        create(:tenant, name: 'ゲーム攻略掲示板', identifier: 'game-strategy',
                        description: 'ゲームの攻略情報を共有する掲示板です。')

        case test_case[:login]
        when :user
          login_as user
        when :moderator
          login_as(moderator, scope: :moderator)
        end

        # テナント一覧でテナントが作成日時の降順で表示される
        visit root_path
        expect(page).to have_content('テナント一覧')

        tenant_cards = all('.tenant-card')
        expect(tenant_cards[0]).to have_content('ゲーム攻略掲示板') # game-strategy
        expect(tenant_cards[1]).to have_content('アイドルファンコミュニティ') # idol-community
        expect(tenant_cards[2]).to have_content('社内フォーラム') # company-forum

        # テナントカードをクリックして詳細ページに遷移
        click_link '社内フォーラム'
        expect(page).to have_current_path(tenant_path(tenant_slug: 'company-forum'))

        # テナント詳細ページでテナント情報が正しく表示される
        expect(page).to have_content('社内フォーラム')
        expect(page).to have_content('@company-forum')
        expect(page).to have_content('説明')
        expect(page).to have_content('社員向けの情報共有・質問・議論のための掲示板です。')

        # テナント詳細ページから戻るリンクでテナント一覧に戻る
        click_link 'テナント一覧に戻る'
        expect(page).to have_current_path(root_path)
        expect(page).to have_content('テナント一覧')
      end
    end
  end

  scenario 'テナントが存在しない場合は空メッセージが表示される' do
    Tenant.delete_all

    visit root_path

    expect(page).to have_content('テナント一覧')
    expect(page).to have_content('テナントが登録されていません')
    expect(page).not_to have_selector('.tenant-card')
  end

  describe 'ページネーション' do
    context '未ログイン時' do
      scenario 'テナント一覧でページネーションが機能する' do
        create_list(:tenant, 30, description: 'テストテナントの説明です。')

        visit root_path
        expect(page).to have_content('テナント一覧')
        expect(page).to have_selector('.pagination')

        # 2ページ目に移動
        click_link '2'

        # 2ページ目のテナントが表示されることを確認
        tenant = Tenant.order(id: :desc).offset(10).first
        expect(page).to have_content(tenant.name)
        expect(page).to have_content("@#{tenant.identifier}")
      end

      scenario 'ページ範囲外にアクセスすると一覧ページにリダイレクトされる' do
        create_list(:tenant, 30, description: 'テストテナントの説明です。')
        visit root_path(other_page: 999)
        expect(page).to have_current_path(root_path)
        expect(page).to have_content('範囲外のリクエストです。')
      end
    end

    context 'ログイン時' do
      before do
        login_as user
      end

      scenario '所属テナントでページネーションが機能する' do
        tenants = create_list(:tenant, 30, description: 'テストテナントの説明です。')
        # ユーザーを最初の25個のテナントに所属させる
        tenants.first(25).each do |tenant|
          create(:tenant_membership, user: user, tenant: tenant)
        end

        visit root_path
        expect(page).to have_content('所属テナント')
        expect(page).to have_selector('.pagination')

        # 所属テナントセクションの2ページ目に移動
        within('.tenant-section', text: '所属テナント') do
          click_link '2'
        end

        # 2ページ目のテナントが表示されることを確認
        member_tenant = user.tenants.order(id: :desc).offset(10).first
        expect(page).to have_content(member_tenant.name)
      end

      scenario 'その他のテナントでページネーションが機能する' do
        tenants = create_list(:tenant, 30, description: 'テストテナントの説明です。')
        # ユーザーを最初の5個のテナントだけに所属させる
        tenants.first(5).each do |tenant|
          create(:tenant_membership, user: user, tenant: tenant)
        end

        visit root_path
        expect(page).to have_content('その他のテナント')

        # その他のテナントセクションの2ページ目に移動
        within('.tenant-section', text: 'その他のテナント') do
          click_link '2'
        end

        # 2ページ目のテナントが表示されることを確認（所属していないテナント）
        other_tenant_ids = Tenant.where.not(id: user.tenants.pluck(:id)).order(id: :desc).offset(10).limit(1).pluck(:id)
        other_tenant = Tenant.find(other_tenant_ids.first)

        # その他のテナントセクション内で確認
        within('.tenant-section', text: 'その他のテナント') do
          expect(page).to have_content(other_tenant.name)
        end
      end

      scenario 'ページ範囲外にアクセスすると一覧ページにリダイレクトされる' do
        create_list(:tenant, 30, description: 'テストテナントの説明です。')
        visit root_path(member_page: 999)
        expect(page).to have_current_path(root_path)
        expect(page).to have_content('範囲外のリクエストです。')
      end
    end
  end

  describe 'テナント識別子の検証' do
    scenario '存在しないテナント識別子でアクセスすると404エラーになる' do
      visit tenant_path(tenant_slug: 'non-existent-tenant')
      expect(page).to have_content('ActiveRecord::RecordNotFound')
    end
  end

  describe 'テナント一覧の分類（ログイン時）' do
    let!(:tenant_a) { create(:tenant, identifier: 'tenant-a', name: 'テナントA') }
    let!(:tenant_b) { create(:tenant, identifier: 'tenant-b', name: 'テナントB') }
    let!(:tenant_c) { create(:tenant, identifier: 'tenant-c', name: 'テナントC') }
    let!(:user_multi) { create(:user) }

    before do
      create(:tenant_membership, tenant: tenant_a, user: user_multi, display_name: 'ユーザーA')
      create(:tenant_membership, tenant: tenant_b, user: user_multi, display_name: 'ユーザーB')
      # tenant_cには所属していない
    end

    scenario '所属テナントとその他のテナントが正しく分類される' do
      login_as user_multi
      visit root_path

      within('.tenant-section', text: '所属テナント') do
        expect(page).to have_content('テナントA')
        expect(page).to have_content('テナントB')
        expect(page).not_to have_content('テナントC')
      end

      within('.tenant-section', text: 'その他のテナント') do
        expect(page).to have_content('テナントC')
        expect(page).not_to have_content('テナントA')
        expect(page).not_to have_content('テナントB')
      end
    end
  end
end
