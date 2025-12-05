# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserDecorator do
  let(:user) { create(:user) }
  let(:tenant) { create(:tenant) }

  describe '#display_name_for' do
    context 'ユーザーがテナントのメンバーの場合' do
      before do
        create(:tenant_membership, user: user, tenant: tenant, display_name: '山田太郎')
      end

      it 'そのテナントでの表示名を返す' do
        expect(user.decorate.display_name_for(tenant)).to eq('山田太郎')
      end
    end

    context 'ユーザーがテナントのメンバーでない場合' do
      it '空文字列を返す' do
        expect(user.decorate.display_name_for(tenant)).to eq('')
      end
    end

    context 'ユーザーが退会済みの場合' do
      before do
        create(:tenant_membership, :unsubscribed, user: user, tenant: tenant, display_name: '山田太郎')
      end

      it '退会済みユーザーの表示名を返す' do
        expect(user.decorate.display_name_for(tenant)).to eq(I18n.t('activerecord.attributes.user.unsubscribed_user'))
      end
    end
  end
end
