# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'テナント', type: :system do
  scenario 'テナント一覧でテナントが識別子順に並んでいる' do
    create(:tenant, name: '社内フォーラム', identifier: 'company-forum',
                    description: '社員向けの情報共有・質問・議論のための掲示板です。')
    create(:tenant, name: 'アイドルファンコミュニティ', identifier: 'idol-community',
                    description: 'アイドルファンが集まるコミュニティ掲示板です。')
    create(:tenant, name: 'ゲーム攻略掲示板', identifier: 'game-strategy',
                    description: 'ゲームの攻略情報を共有する掲示板です。')

    visit root_path

    tenant_cards = all('.tenant-card')
    expect(tenant_cards[0]).to have_content('社内フォーラム') # company-forum
    expect(tenant_cards[1]).to have_content('ゲーム攻略掲示板') # game-strategy
    expect(tenant_cards[2]).to have_content('アイドルファンコミュニティ') # idol-community
  end

  scenario 'テナントカードをクリックすると詳細ページに遷移する' do
    create(:tenant, name: '社内フォーラム', identifier: 'company-forum',
                    description: '社員向けの情報共有・質問・議論のための掲示板です。')

    visit root_path
    click_link '社内フォーラム'

    expect(page).to have_current_path(tenant_root_path(tenant_slug: 'company-forum'))
    expect(page).to have_content('社内フォーラム')
    expect(page).to have_content('@company-forum')
  end

  scenario 'テナントが存在しない場合は空メッセージが表示される' do
    visit root_path

    expect(page).to have_content('テナント一覧')
    expect(page).to have_content('テナントが登録されていません')
    expect(page).not_to have_selector('.tenant-card')
  end

  scenario 'テナント詳細ページでテナント情報が正しく表示される' do
    create(:tenant, name: '社内フォーラム', identifier: 'company-forum',
                    description: '社員向けの情報共有・質問・議論のための掲示板です。')

    visit tenant_root_path(tenant_slug: 'company-forum')

    expect(page).to have_content('社内フォーラム')
    expect(page).to have_content('@company-forum')
    expect(page).to have_content('説明')
    expect(page).to have_content('社員向けの情報共有・質問・議論のための掲示板です。')
  end

  scenario 'テナント詳細ページから戻るリンクでテナント一覧に戻る' do
    create(:tenant, name: '社内フォーラム', identifier: 'company-forum',
                    description: '社員向けの情報共有・質問・議論のための掲示板です。')

    visit tenant_root_path(tenant_slug: 'company-forum')
    click_link 'テナント一覧に戻る'

    expect(page).to have_current_path(root_path)
    expect(page).to have_content('テナント一覧')
  end
end
