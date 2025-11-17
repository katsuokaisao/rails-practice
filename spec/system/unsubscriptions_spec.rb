# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '退会機能', type: :system do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:tenant_a) { create(:tenant, identifier: 'tenant-a', name: 'テナントA') }
  let(:tenant_b) { create(:tenant, identifier: 'tenant-b', name: 'テナントB') }
  let(:tenant_c) { create(:tenant, identifier: 'tenant-c', name: 'テナントC') }
  let!(:membership_a) { create(:tenant_membership, user: user, tenant: tenant_a, display_name: 'ユーザーA') }
  let!(:membership_b) { create(:tenant_membership, user: user, tenant: tenant_b, display_name: 'ユーザーB') }
  let!(:membership_c) { create(:tenant_membership, user: user, tenant: tenant_c, display_name: 'ユーザーC') }

  before do
    login_as user
  end

  describe '退会フォームへのアクセス' do
    scenario 'ログインユーザーが退会フォームにアクセスできる' do
      visit new_unsubscription_path

      expect(page).to have_content('テナント退会')
      expect(page).to have_content('テナントA')
      expect(page).to have_content('テナントB')
      expect(page).to have_content('テナントC')
    end

    scenario '退会フォームに所属テナントのポリシー情報が表示される' do
      visit new_unsubscription_path

      expect(page).to have_css('.tenant-policies')
    end
  end

  describe 'テナントからの退会' do
    scenario 'ユーザーが単一のテナントから退会できる' do
      visit new_unsubscription_path

      within('.tenant-item', text: 'テナントA') do
        find('input[type="checkbox"]').check
      end

      accept_confirm do
        click_button '退会する'
      end

      expect(page).to have_content('退会処理を開始しました')
      expect(page).to have_current_path(new_unsubscription_path)

      expect(page).not_to have_content('テナントA')
      expect(page).to have_content('テナントB')
      expect(page).to have_content('テナントC')
    end

    scenario 'ユーザーが複数のテナントから同時に退会できる' do
      visit new_unsubscription_path

      within('.tenant-item', text: 'テナントA') do
        find('input[type="checkbox"]').check
      end
      within('.tenant-item', text: 'テナントB') do
        find('input[type="checkbox"]').check
      end

      accept_confirm do
        click_button '退会する'
      end

      expect(page).to have_content('退会処理を開始しました')

      expect(page).not_to have_content('テナントA')
      expect(page).not_to have_content('テナントB')
      expect(page).to have_content('テナントC')
    end

    scenario 'テナントが選択されていない場合はエラーメッセージが表示される' do
      visit new_unsubscription_path

      page.execute_script("document.querySelector('[data-unsubscription-target=\"submitButton\"]').disabled = false")

      click_button '退会する'

      expect(page).to have_content('退会するテナントを選択してください')
      expect(page).to have_current_path(new_unsubscription_path)
    end
  end

  describe '退会後のアクセス制限' do
    let!(:topic) { create(:topic, tenant: tenant_a, author: user) }

    scenario '退会したテナントにはトピックを投稿できない' do
      membership_a.update!(unsubscribed_at: Time.current)

      visit tenant_path(tenant_slug: tenant_a.identifier)

      expect(page).not_to have_link('お題を投稿する')
    end

    scenario '退会したテナントのトピックにはコメントを投稿できない' do
      membership_a.update!(unsubscribed_at: Time.current)

      visit tenant_topic_path(tenant_slug: tenant_a.identifier, id: topic.id)

      expect(page).not_to have_button('投稿する')
      expect(page).not_to have_field('comment_content')
    end

    scenario '退会したテナントは閲覧できる' do
      membership_a.update!(unsubscribed_at: Time.current)

      visit tenant_path(tenant_slug: tenant_a.identifier)

      expect(page).to have_content('テナントA')
      expect(page).to have_content(topic.title)
    end

    scenario '退会したテナントのトピックは閲覧できる' do
      membership_a.update!(unsubscribed_at: Time.current)

      visit tenant_topic_path(tenant_slug: tenant_a.identifier, id: topic.id)

      expect(page).to have_content(topic.title)
    end
  end

  describe 'すべて選択/すべて解除ボタン' do
    scenario 'すべて選択ボタンで全テナントが選択される' do
      visit new_unsubscription_path

      click_button '全て選択'

      expect(all('.tenant-item input[type="checkbox"]')).to all(be_checked)
    end

    scenario 'すべて解除ボタンで全テナントの選択が解除される' do
      visit new_unsubscription_path

      click_button '全て選択'
      click_button '全て解除'

      all('.tenant-item input[type="checkbox"]').each do |checkbox|
        expect(checkbox).not_to be_checked
      end
    end

    scenario 'テナントが選択されていない場合、送信ボタンが無効化される' do
      visit new_unsubscription_path

      submit_button = find('[data-unsubscription-target="submitButton"]')
      expect(submit_button).to be_disabled
    end

    scenario 'テナントが選択されると、送信ボタンが有効化される' do
      visit new_unsubscription_path

      within('.tenant-item', text: 'テナントA') do
        find('input[type="checkbox"]').check
      end

      submit_button = find('[data-unsubscription-target="submitButton"]')
      expect(submit_button).not_to be_disabled
    end
  end

  describe '確認ダイアログ' do
    scenario '退会実行時に確認ダイアログが表示される' do
      visit new_unsubscription_path

      within('.tenant-item', text: 'テナントA') do
        find('input[type="checkbox"]').check
      end

      dismiss_confirm do
        click_button '退会する'
      end

      expect(page).to have_current_path(new_unsubscription_path)
      expect(page).to have_content('テナントA')
    end

    scenario '確認ダイアログでOKを押すと退会処理が実行される' do
      visit new_unsubscription_path

      within('.tenant-item', text: 'テナントA') do
        find('input[type="checkbox"]').check
      end

      accept_confirm do
        click_button '退会する'
      end

      expect(page).to have_content('退会処理を開始しました')
    end
  end

  describe '所属テナントがない場合' do
    scenario '所属テナントがない場合、メッセージが表示される' do
      user.tenant_memberships.destroy_all

      visit new_unsubscription_path

      expect(page).to have_content('所属しているテナントがありません')
      expect(page).not_to have_button('退会する')
    end
  end

  describe '退会後の一覧表示' do
    scenario '退会したテナントは所属テナント一覧に表示されない' do
      membership_a.update!(unsubscribed_at: Time.current)

      visit root_path

      within('.tenant-section', text: '所属テナント') do
        expect(page).not_to have_content('テナントA')
        expect(page).to have_content('テナントB')
        expect(page).to have_content('テナントC')
      end

      within('.tenant-section', text: 'その他のテナント') do
        expect(page).to have_content('テナントA')
      end
    end

    scenario '退会したテナントはプロフィール画面の所属テナント一覧に表示されない' do
      membership_a.update!(unsubscribed_at: Time.current)

      visit edit_user_profile_path

      expect(page).not_to have_content('テナントA')
      expect(page).to have_content('テナントB')
      expect(page).to have_content('テナントC')
    end
  end
end
