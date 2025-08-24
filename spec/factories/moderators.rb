# frozen_string_literal: true

FactoryBot.define do
  factory :moderator do
    sequence(:nickname) { |n| "moderator#{n}" }
    password { 'password' }
    password_confirmation { 'password' }
  end
end
