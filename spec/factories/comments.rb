# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
#
#  id                       :bigint           not null, primary key
#  content                  :text(65535)      not null
#  current_version_no       :integer          not null
#  hidden                   :boolean          default(FALSE), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  author_id                :bigint           not null
#  hidden_cause_decision_id :bigint
#  topic_id                 :bigint           not null
#
# Indexes
#
#  idx_comments_author_id            (author_id)
#  idx_comments_topic_id_created_at  (topic_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (topic_id => topics.id)
#
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

    trait :short_content do
      content { Faker::Lorem.paragraphs(number: 1).join }
    end
  end
end
