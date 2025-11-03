# frozen_string_literal: true

# == Schema Information
#
# Table name: tenant_invitations
#
#  id                                                               :bigint           not null, primary key
#  status((enum: 'pending' | 'accepted' | 'rejected' | 'canceled')) :string(255)      default("pending"), not null
#  created_at                                                       :datetime         not null
#  updated_at                                                       :datetime         not null
#  invited_user_id                                                  :bigint           not null
#  inviter_id                                                       :bigint           not null
#  tenant_id                                                        :bigint           not null
#
# Indexes
#
#  idx_tenant_invitations_invited_user_status  (invited_user_id,status)
#  idx_tenant_invitations_inviter              (inviter_id)
#  idx_tenant_invitations_tenant_user_pending  (tenant_id,invited_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (invited_user_id => users.id)
#  fk_rails_...  (inviter_id => users.id)
#  fk_rails_...  (tenant_id => tenants.id)
#
require 'rails_helper'

RSpec.describe TenantInvitation, type: :model do
  describe 'バリデーション' do
    let(:tenant) { create(:tenant) }
    let(:inviter) { create(:user) }
    let(:invited_user) { create(:user) }

    before do
      create(:tenant_membership, tenant: tenant, user: inviter, display_name: '招待者')
    end

    describe 'invited_user_id（招待対象ユーザー）' do
      it '必須項目である' do
        invitation = build(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user_id: nil)
        expect(invitation).to be_invalid
        expect(invitation.errors[:invited_user_id]).to include('を入力してください')
      end

      it '存在しないユーザーIDの場合はエラー' do
        invitation = build(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user_id: 99_999_999)
        expect(invitation).to be_invalid
        expect(invitation.errors[:invited_user_id]).to include('存在しないユーザです')
      end

      it '自分自身を招待できない' do
        invitation = build(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: inviter)
        expect(invitation).to be_invalid
        expect(invitation.errors[:invited_user_id]).to include('は自分自身を指定できません')
      end

      it '同一テナント内でpending状態の招待が重複できない' do
        create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :pending)

        duplicate_invitation = build(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user,
                                                         status: :pending)
        expect(duplicate_invitation).to be_invalid
        expect(duplicate_invitation.errors[:invited_user_id]).to include('には既に招待を送信しています')
      end

      it 'accepted状態の場合は同じユーザーへの新規招待が可能' do
        create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :accepted)

        new_invitation = build(:tenant_invitation,
                               tenant: tenant, inviter: inviter, invited_user: invited_user, status: :pending)
        expect(new_invitation).to be_valid
      end

      it 'rejected状態の場合は同じユーザーへの新規招待が可能' do
        create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :rejected)

        new_invitation = build(:tenant_invitation,
                               tenant: tenant, inviter: inviter, invited_user: invited_user,
                               status: :pending)
        expect(new_invitation).to be_valid
      end

      it '既にテナントメンバーのユーザーは招待できない' do
        create(:tenant_membership, tenant: tenant, user: invited_user, display_name: 'メンバー')

        invitation = build(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user)
        expect(invitation).to be_invalid
        expect(invitation.errors[:invited_user_id]).to include('は既にメンバーです')
      end

      it '異なるテナントであれば同じユーザーを招待できる' do
        other_tenant = create(:tenant)
        create(:tenant_membership, tenant: other_tenant, user: inviter, display_name: '招待者')
        create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :pending)

        invitation_other_tenant = build(:tenant_invitation, tenant: other_tenant, inviter: inviter,
                                                            invited_user: invited_user, status: :pending)
        expect(invitation_other_tenant).to be_valid
      end
    end
  end

  describe 'インスタンスメソッド' do
    describe '#accept!' do
      let(:tenant) { create(:tenant, name: 'テストテナント') }
      let(:inviter) { create(:user) }
      let(:invited_user) { create(:user) }
      let(:invitation) do
        create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :pending)
      end

      before do
        create(:tenant_membership, tenant: tenant, user: inviter, display_name: '招待者')
      end

      context '正常系' do
        it 'TenantMembershipが作成され、ステータスがacceptedに変更され、display_nameが反映される' do
          expect do
            invitation.accept!(display_name: 'カスタム表示名')
          end.to change(TenantMembership, :count).by(1)
                                                 .and change { invitation.reload.status }.from('pending').to('accepted')

          membership = TenantMembership.find_by(tenant: tenant, user: invited_user)
          expect(membership).to be_present
          expect(membership.display_name).to eq('カスタム表示名')
        end
      end

      context '異常系' do
        it '無効なdisplay_nameの場合、エラーが発生する' do
          expect do
            invitation.accept!(display_name: '')
          end.to raise_error(ActiveRecord::RecordInvalid)

          # メンバーシップが作成されていないことを確認
          membership = TenantMembership.find_by(tenant: tenant, user: invited_user)
          expect(membership).to be_nil

          # ステータスも変更されていないことを確認
          expect(invitation.reload.status).to eq('pending')
        end

        it '51文字のdisplay_nameでエラーが発生する' do
          long_name = 'あ' * 51
          expect do
            invitation.accept!(display_name: long_name)
          end.to raise_error(ActiveRecord::RecordInvalid)

          # メンバーシップが作成されていないことを確認
          membership = TenantMembership.find_by(tenant: tenant, user: invited_user)
          expect(membership).to be_nil

          # ステータスも変更されていないことを確認
          expect(invitation.reload.status).to eq('pending')
        end
      end
    end

    describe '#reject!' do
      let(:tenant) { create(:tenant) }
      let(:inviter) { create(:user) }
      let(:invited_user) { create(:user) }
      let(:invitation) do
        create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :pending)
      end

      it 'ステータスがrejectedに変更される' do
        invitation.reject!
        expect(invitation.reload.status).to eq('rejected')
      end
    end

    describe '#already_member?' do
      let(:tenant) { create(:tenant) }
      let(:inviter) { create(:user) }
      let(:invited_user) { create(:user) }

      it 'テナントメンバーの場合はtrueを返す' do
        create(:tenant_membership, tenant: tenant, user: invited_user, display_name: 'メンバー')
        invitation = build(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user)

        expect(invitation.already_member?).to be true
      end

      it 'テナントメンバーでない場合はfalseを返す' do
        invitation = build(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user)

        expect(invitation.already_member?).to be false
      end
    end
  end
end
