# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                 :bigint           not null, primary key
#  encrypted_password :string(255)      not null
#  nickname           :string(255)      not null
#  suspended_until    :datetime
#  time_zone          :string(255)      default("Tokyo"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  idx_users_nickname  (nickname) UNIQUE
#
require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }
  let(:tenant_a) { create(:tenant, identifier: 'tenant-a') }
  let(:tenant_b) { create(:tenant, identifier: 'tenant-b') }

  describe 'バリデーション' do
    context '新規作成時' do
      it '有効な場合は保存できる' do
        user = build(:user)
        expect(user).to be_valid
      end

      it 'nickname が必須' do
        user = build(:user, nickname: nil)
        expect(user).to be_invalid
        expect(user.errors[:nickname]).to be_present
      end

      it 'nickname は一意' do
        create(:user, nickname: 'dup')
        user = build(:user, nickname: 'dup')
        expect(user).to be_invalid
        expect(user.errors[:nickname]).to be_present
      end

      it 'nickname の長さが範囲外だと無効' do
        too_short = build(:user, nickname: '')
        too_long  = build(:user, nickname: 'a' * 51)

        expect(too_short).to be_invalid
        expect(too_short.errors[:nickname]).to be_present

        expect(too_long).to be_invalid
        expect(too_long.errors[:nickname]).to be_present
      end

      it 'password は必須' do
        user = build(:user, password: nil, password_confirmation: nil)
        expect(user).to be_invalid
        expect(user.errors[:password]).to be_present
      end

      it 'password_confirmation と一致しないと無効' do
        user = build(:user, password: 'Abcdef12!', password_confirmation: 'Mismatch1!')
        expect(user).to be_invalid
        expect(user.errors[:password_confirmation]).to be_present
      end

      it 'password の長さが最小未満/最大超過だと無効' do
        short = build(:user, password: 'A1!a' * 1, password_confirmation: 'A1!a' * 1) # 4文字
        long  = build(:user, password: "A1!#{'a' * 48}", password_confirmation: "A1!#{'a' * 48}") # 51文字

        expect(short).to be_invalid
        expect(short.errors[:password]).to be_present

        expect(long).to be_invalid
        expect(long.errors[:password]).to be_present
      end

      context 'password のフォーマット (ASCII印字可能・スペース不可)' do
        it 'ASCII印字可能（例: Abcdef12!）は有効' do
          user = build(:user, password: 'Abcdef12!', password_confirmation: 'Abcdef12!')
          expect(user).to be_valid
        end

        it 'スペースを含むと無効' do
          user = build(:user, password: 'Abcd ef12!', password_confirmation: 'Abcd ef12!')
          expect(user).to be_invalid
          expect(user.errors[:password]).to be_present
        end

        it '非ASCII（例: 日本語, 全角記号）を含むと無効' do
          user = build(:user, password: 'Abcd日本語12!', password_confirmation: 'Abcd日本語12!')
          expect(user).to be_invalid
          expect(user.errors[:password]).to be_present

          user2 = build(:user, password: 'Ａbcdef12!', password_confirmation: 'Ａbcdef12!')
          expect(user2).to be_invalid
          expect(user2.errors[:password]).to be_present
        end
      end
    end

    context '更新時' do
      let!(:user) { create(:user) }

      it 'password を変更しない更新は password がなくても更新できる' do
        expect(user.update(nickname: 'renamed', password: '', password_confirmation: '')).to be true
      end

      it 'password_confirmation だけは無効' do
        user.update(password: '', password_confirmation: 'Newpass12!')
        expect(user.errors[:password]).to be_present
      end

      it '有効なパスワードの場合は更新できる' do
        expect(
          user.update(password: 'Newpass12!', password_confirmation: 'Newpass12!')
        ).to be true
      end

      it '無効なパスワードの場合は更新できない' do
        user.update(password: 'New pass', password_confirmation: 'New pass')
        expect(user.errors[:password]).to be_present
      end

      it 'パスワードの長さが最小未満だと無効' do
        user.update(password: 'A1!a', password_confirmation: 'A1!a')
        expect(user.errors[:password]).to be_present
      end
    end
  end

  describe '#member_of?' do
    context 'ユーザーがテナントのメンバーの場合' do
      before do
        create(:tenant_membership, user: user, tenant: tenant_a)
      end

      it 'trueを返す' do
        expect(user.member_of?(tenant_a)).to be true
      end
    end

    context 'ユーザーがテナントのメンバーでない場合' do
      it 'falseを返す' do
        expect(user.member_of?(tenant_a)).to be false
      end
    end
  end

  describe '#display_name_for' do
    context 'ユーザーがテナントのメンバーの場合' do
      before do
        create(:tenant_membership, user: user, tenant: tenant_a, display_name: '山田太郎')
      end

      it 'そのテナントでの表示名を返す' do
        expect(user.display_name_for(tenant_a)).to eq('山田太郎')
      end
    end

    context 'ユーザーがテナントのメンバーでない場合' do
      it '空文字列を返す' do
        expect(user.display_name_for(tenant_a)).to eq('')
      end
    end
  end
end
