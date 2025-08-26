# frozen_string_literal: true

FactoryBot.define do
  factory :comment_history do
    association :comment
    topic { comment.topic }
    author { comment.author }

    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    version_no { comment.current_version_no + 1 }

    after(:create) do |comment_history|
      comment_history.comment.update!(current_version_no: comment_history.version_no, content: comment_history.content)
    end
  end
end
