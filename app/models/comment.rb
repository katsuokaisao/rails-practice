# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'User'
  has_many :histories, class_name: 'CommentHistory', dependent: :restrict_with_error

  validates :content, presence: true
  validates :current_version_no, presence: true

  def self.create_with_history!(topic:, author:, content:)
    transaction do
      comment = create!(
        topic: topic,
        author: author,
        content: content,
        current_version_no: 1
      )
      comment.histories.create!(
        topic: topic,
        author: author,
        content: content,
        version_no: 1
      )
      comment
    end
  end

  def update_content!(content)
    transaction do
      v = current_version_no + 1
      update!(content: content, current_version_no: v)
      histories.create!(
        topic: topic,
        author: author,
        content: content,
        version_no: v
      )
    end
  end
end
