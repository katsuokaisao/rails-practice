# frozen_string_literal: true

create_table :tenant_invitations, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.bigint   'tenant_id',        null: false
  t.bigint   'inviter_id',       null: false
  t.bigint   'invited_user_id',  null: false
  t.string   'status',           null: false, default: 'pending',
                                 comment: "(enum: 'pending' | 'accepted' | 'rejected' | 'canceled')"
  t.datetime 'created_at',       null: false
  t.datetime 'updated_at',       null: false

  t.index %w[tenant_id inviter_id invited_user_id],
          where: "status = 'pending'",
          unique: true,
          name: 'idx_tenant_invitations_tenant_inviter_user_pending'
  t.index %w[invited_user_id status], name: 'idx_tenant_invitations_invited_user_status'
  t.index %w[inviter_id], name: 'idx_tenant_invitations_inviter'
end

add_foreign_key 'tenant_invitations', 'tenants', column: 'tenant_id'
add_foreign_key 'tenant_invitations', 'users',   column: 'inviter_id'
add_foreign_key 'tenant_invitations', 'users',   column: 'invited_user_id'
