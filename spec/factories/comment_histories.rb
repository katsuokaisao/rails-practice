# frozen_string_literal: true

FactoryBot.define do
  factory :comment_history do
    association :comment
    topic { comment.topic }
    author { comment.author }
    content { comment.content }
    version_no { comment.current_version_no }
  end
end
