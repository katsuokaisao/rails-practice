# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:nickname) { |n| "test#{n}" }
    password { 'password' }
    password_confirmation { 'password' }
  end
end
