# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    association :topic
    association :author, factory: :user

    content { Faker::Lorem.paragraphs(number: 3).join("\n") }
    current_version_no { 1 }
    hidden { false }

    after(:create) do |comment|
      create(:comment_history, comment: comment)
    end
  end
end
