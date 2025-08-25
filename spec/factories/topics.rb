# frozen_string_literal: true

FactoryBot.define do
  factory :topic do
    association :author, factory: :user
    sequence(:title) { |n| "タイトル#{n}" }
  end
end
