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
    describe '#accept' do
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
          membership = invited_user.tenant_memberships.new(
            tenant: tenant,
            display_name: 'カスタム表示名'
          )

          expect do
            result = invitation.accept(membership)
            expect(result).to be true
          end.to change(TenantMembership, :count).by(1)
             .and change { invitation.reload.status }.from('pending').to('accepted')

          expect(membership.reload.display_name).to eq('カスタム表示名')
        end
      end

      context '異常系' do
        it '無効なdisplay_nameの場合、falseを返しステータスは変更されない' do
          membership = invited_user.tenant_memberships.new(
            tenant: tenant,
            display_name: ''
          )

          expect(invitation.accept(membership)).to be false
          expect(TenantMembership.find_by(tenant: tenant, user: invited_user)).to be_nil
          expect(invitation.reload.status).to eq('pending')
        end

        it '51文字のdisplay_nameでfalseを返す' do
          long_name = 'あ' * 51
          membership = invited_user.tenant_memberships.new(
            tenant: tenant,
            display_name: long_name
          )

          expect(invitation.accept(membership)).to be false
          expect(TenantMembership.find_by(tenant: tenant, user: invited_user)).to be_nil
          expect(invitation.reload.status).to eq('pending')
        end

        it '既にメンバーの場合はfalseを返す' do
          # invitationを先に作成してからメンバーを作成（バリデーション回避）
          invitation
          create(:tenant_membership, tenant: tenant, user: invited_user, display_name: 'メンバー')

          membership = invited_user.tenant_memberships.new(
            tenant: tenant,
            display_name: '表示名2'
          )

          expect(invitation.accept(membership)).to be false
        end
      end

      context '同時処理' do
        it '同時に受け入れようとした場合、片方だけが成功する' do
          threads = []
          results = []

          2.times do |i|
            threads << Thread.new do
              membership = invited_user.tenant_memberships.new(
                tenant: tenant,
                display_name: "表示名#{i}"
              )
              results << invitation.accept(membership)
            end
          end

          threads.each(&:join)

          expect(results.count(true)).to eq(1)
          expect(results.count(false)).to eq(1)
          expect(TenantMembership.where(tenant: tenant, user: invited_user).count).to eq(1)
        end
      end
    end

    describe '#reject' do
      let(:tenant) { create(:tenant) }
      let(:inviter) { create(:user) }
      let(:invited_user) { create(:user) }
      let(:invitation) do
        create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :pending)
      end

      context '正常系' do
        it 'ステータスがrejectedに変更される' do
          expect(invitation.reject).to be true
          expect(invitation.reload.status).to eq('rejected')
        end
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

  describe 'counter_culture' do
    let(:tenant) { create(:tenant) }
    let(:inviter) { create(:user) }
    let(:invited_user) { create(:user) }

    before do
      create(:tenant_membership, tenant: tenant, user: inviter, display_name: '招待者')
    end

    it '招待作成時にpending_invitations_countがインクリメントされる' do
      expect do
        create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :pending)
      end.to change { invited_user.reload.pending_invitations_count }.by(1)
    end

    it '招待受け入れ時にpending_invitations_countがデクリメントされる' do
      invitation = create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user,
                                              status: :pending)
      membership = invited_user.tenant_memberships.new(tenant: tenant, display_name: '表示名')

      expect do
        invitation.accept(membership)
      end.to change { invited_user.reload.pending_invitations_count }.by(-1)
    end

    it '招待拒否時にpending_invitations_countがデクリメントされる' do
      invitation = create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user,
                                              status: :pending)

      expect do
        invitation.reject
      end.to change { invited_user.reload.pending_invitations_count }.by(-1)
    end

    it '複数の招待がある場合、正しくカウントされる' do
      tenant2 = create(:tenant)
      create(:tenant_membership, tenant: tenant2, user: inviter, display_name: '招待者2')

      create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :pending)
      create(:tenant_invitation, tenant: tenant2, inviter: inviter, invited_user: invited_user, status: :pending)

      expect(invited_user.reload.pending_invitations_count).to eq(2)
    end

    it 'accepted状態の招待はカウントされない' do
      create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :accepted)

      expect(invited_user.reload.pending_invitations_count).to eq(0)
    end

    it 'rejected状態の招待はカウントされない' do
      create(:tenant_invitation, tenant: tenant, inviter: inviter, invited_user: invited_user, status: :rejected)

      expect(invited_user.reload.pending_invitations_count).to eq(0)
    end
  end
end
