# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'User'
  belongs_to :hidden_cause_decision, class_name: 'Decision', optional: true

  has_many :histories, class_name: 'CommentHistory', dependent: :restrict_with_error
  has_many :reports, class_name: 'Report', foreign_key: 'target_comment_id',
                     dependent: :restrict_with_error, inverse_of: :target_comment

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

  def hide_by_decision!(decision)
    update!(
      hidden: true,
      hidden_cause_decision: decision
    )
  end

  def hidden?
    hidden
  end

  def invisible?
    hidden? || author.suspended?
  end
end
