# frozen_string_literal: true

# == Schema Information
#
# Table name: comment_histories
#
#  id         :bigint           not null, primary key
#  content    :text(65535)      not null
#  version_no :integer          not null
#  created_at :datetime         not null
#  author_id  :bigint           not null
#  comment_id :bigint           not null
#  topic_id   :bigint           not null
#
# Indexes
#
#  idx_comment_histories_comment_id  (comment_id,version_no) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (comment_id => comments.id)
#
FactoryBot.define do
  factory :comment_history do
    association :comment
    topic { comment.topic }
    author { comment.author }
    content { comment.content }
    version_no { comment.current_version_no }
  end
end
