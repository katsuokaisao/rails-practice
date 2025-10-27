# frozen_string_literal: true

# == Schema Information
#
# Table name: tenant_memberships
#
#  id           :bigint           not null, primary key
#  display_name :string(255)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  tenant_id    :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  idx_tenant_memberships_tenant_display_name  (tenant_id,display_name) UNIQUE
#  idx_tenant_memberships_tenant_user          (tenant_id,user_id) UNIQUE
#  idx_tenant_memberships_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (tenant_id => tenants.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe TenantMembership, type: :model do
  describe 'バリデーション' do
    context 'display_name' do
      it '異なるテナントであれば同じ表示名を使用できる' do
        tenant_a = create(:tenant, identifier: 'tenant-a')
        tenant_b = create(:tenant, identifier: 'tenant-b')
        user = create(:user)
        create(:tenant_membership, tenant: tenant_a, user: user, display_name: '山田太郎')

        membership_b = build(:tenant_membership, tenant: tenant_b, display_name: '山田太郎')
        expect(membership_b).to be_valid
      end

      it '同一テナント内で display_name が重複している場合は無効' do
        tenant = create(:tenant)
        create(:tenant_membership, tenant: tenant, display_name: '山田太郎')

        duplicate_membership = build(:tenant_membership, tenant: tenant, display_name: '山田太郎')
        expect(duplicate_membership).to be_invalid
        expect(duplicate_membership.errors[:display_name]).to include('はこのテナント内で既に使用されています')
      end

      it '大文字小文字を区別する（case_sensitive: true）' do
        tenant = create(:tenant)
        create(:tenant_membership, tenant: tenant, display_name: 'Yamada')

        different_case = build(:tenant_membership, tenant: tenant, display_name: 'yamada')
        expect(different_case).to be_valid
      end
    end

    context 'user_id' do
      it '同一ユーザーが複数のテナントに所属できる' do
        user = create(:user)
        create(:tenant_membership, user: user, display_name: '山田太郎')

        membership_b = build(:tenant_membership, user: user, display_name: 'たろちゃん')
        expect(membership_b).to be_valid
      end

      it '同一ユーザーが同一テナントに重複して所属できない' do
        tenant = create(:tenant)
        user = create(:user)
        create(:tenant_membership, tenant: tenant, user: user, display_name: '表示名1')

        duplicate_membership = build(:tenant_membership, tenant: tenant, user: user, display_name: '表示名2')
        expect(duplicate_membership).to be_invalid
        expect(duplicate_membership.errors[:user_id]).to include('は既にこのテナントのメンバーです')
      end

      it 'user_id が必須' do
        membership = build(:tenant_membership, user: nil)
        expect(membership).to be_invalid
        expect(membership.errors[:user]).to be_present
      end
    end

    context 'tenant_id' do
      it 'tenant_id が必須' do
        membership = build(:tenant_membership, tenant: nil)
        expect(membership).to be_invalid
        expect(membership.errors[:tenant]).to be_present
      end
    end
  end
end
