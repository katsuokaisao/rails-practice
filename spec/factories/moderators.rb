# frozen_string_literal: true

# == Schema Information
#
# Table name: moderators
#
#  id                 :bigint           not null, primary key
#  encrypted_password :string(255)      not null
#  time_zone          :string(255)      default("Tokyo"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  login_id           :string(255)      not null
#  tenant_id          :bigint           not null
#
# Indexes
#
#  idx_moderators_login_id   (login_id) UNIQUE
#  idx_moderators_tenant_id  (tenant_id)
#
FactoryBot.define do
  factory :moderator do
    association :tenant
    sequence(:login_id) { |n| "moderator#{n}" }
    password { 'password' }
    password_confirmation { 'password' }
  end
end
