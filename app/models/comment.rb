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
class Comment < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'User'
  belongs_to :hidden_cause_decision, class_name: 'Decision', optional: true

  counter_culture :topic, column_name: 'total_comment'

  has_many :histories, class_name: 'CommentHistory', dependent: :restrict_with_error
  has_many :reports, class_name: 'Report', foreign_key: 'target_comment_id',
                     dependent: :restrict_with_error, inverse_of: :target_comment

  validates :content, presence: true, length: { maximum: 5000 }
  validates :current_version_no, presence: true, numericality: { only_integer: true, greater_than: 0 }

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
