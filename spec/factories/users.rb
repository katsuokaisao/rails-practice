# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                 :bigint           not null, primary key
#  encrypted_password :string(255)      not null
#  nickname           :string(255)      not null
#  time_zone          :string(255)      default("Tokyo"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  idx_users_nickname  (nickname) UNIQUE
#
FactoryBot.define do
  factory :user do
    sequence(:nickname) { |n| "test#{n}" }
    password { 'password' }
    password_confirmation { 'password' }

    trait :suspended do
      after(:create) do |user|
        user.suspend!(1.month.from_now)
      end
    end
  end
end
