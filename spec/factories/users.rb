# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                        :bigint           not null, primary key
#  encrypted_password        :string(255)      not null
#  pending_invitations_count :integer          default(0), not null
#  time_zone                 :string(255)      default("Tokyo"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  login_id                  :string(255)      not null
#
# Indexes
#
#  idx_users_login_id  (login_id) UNIQUE
#
FactoryBot.define do
  factory :user do
    sequence(:login_id) { |n| "test#{n}" }
    time_zone { 'Tokyo' }
    password { 'password' }
    password_confirmation { 'password' }

    trait :with_tenant_membership do
      transient do
        tenant { nil }
        display_name { nil }
      end

      after(:create) do |user, evaluator|
        tenant = evaluator.tenant || create(:tenant)
        display_name = evaluator.display_name || "ユーザー#{user.id}"
        create(:tenant_membership, user: user, tenant: tenant, display_name: display_name)
      end
    end

    trait :with_multiple_tenants do
      transient do
        tenant_count { 3 }
        tenants { [] }
      end

      after(:create) do |user, evaluator|
        tenants_to_join = if evaluator.tenants.any?
                            evaluator.tenants
                          else
                            create_list(:tenant, evaluator.tenant_count)
                          end

        tenants_to_join.each do |tenant|
          create(:tenant_membership,
                 user: user,
                 tenant: tenant,
                 display_name: "ユーザー#{user.id}")
        end
      end
    end

    trait :suspended_in do
      transient do
        tenant { nil }
        display_name { nil }
      end

      after(:create) do |user, evaluator|
        raise ArgumentError, 'tenant is required for :suspended_in trait' if evaluator.tenant.nil?

        display_name = evaluator.display_name || "停止ユーザー#{user.id}"
        create(:tenant_membership, :suspended, user: user, tenant: evaluator.tenant, display_name: display_name)
      end
    end
  end
end
