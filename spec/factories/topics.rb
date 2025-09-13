# frozen_string_literal: true

# == Schema Information
#
# Table name: topics
#
#  id            :bigint           not null, primary key
#  title         :string(255)      not null
#  total_comment :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  author_id     :bigint           not null
#
# Indexes
#
#  idx_topics_author_id   (author_id)
#  idx_topics_created_at  (created_at)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#
FactoryBot.define do
  factory :topic do
    association :author, factory: :user
    sequence(:title) { |n| "タイトル#{n}" }
  end
end
