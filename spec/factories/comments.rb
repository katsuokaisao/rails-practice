# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    association :topic
    association :author, factory: :user

    content { Faker::Lorem.paragraph }
    current_version_no { 1 }
    hidden { false }
  end
end
