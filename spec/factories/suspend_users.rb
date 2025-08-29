# frozen_string_literal: true

FactoryBot.define do
  factory :suspend_user do
    association :user
    suspended_until { 1.day.from_now }
  end
end
