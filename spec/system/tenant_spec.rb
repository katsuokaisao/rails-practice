# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'テナント', type: :system do
  let!(:user) { create(:user) }
  let!(:moderator) { create(:moderator) }

  describe '認可' do
    [
      { role: '未ログインユーザー', login: :none },
      { role: 'ログインユーザー', login: :user },
      { role: 'モデレーター', login: :moderator }
    ].each do |test_case|
      scenario "#{test_case[:role]}がテナント一覧から詳細ページへの一連の操作ができる" do
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

        # テナント一覧でテナントが識別子順に並んでいることを確認
        visit root_path
        expect(page).to have_content('テナント一覧')

        tenant_cards = all('.tenant-card')
        expect(tenant_cards[0]).to have_content('社内フォーラム') # company-forum
        expect(tenant_cards[1]).to have_content('ゲーム攻略掲示板') # game-strategy
        expect(tenant_cards[2]).to have_content('アイドルファンコミュニティ') # idol-community

        # テナントカードをクリックして詳細ページに遷移
        click_link '社内フォーラム'
        expect(page).to have_current_path(tenant_root_path(tenant_slug: 'company-forum'))

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
    visit root_path

    expect(page).to have_content('テナント一覧')
    expect(page).to have_content('テナントが登録されていません')
    expect(page).not_to have_selector('.tenant-card')
  end
end
