# frozen_string_literal: true

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
