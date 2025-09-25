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
  include Reportable
  include CommentSharedBehavior

  belongs_to :hidden_cause_decision, class_name: 'Decision', optional: true
  has_many :histories, class_name: 'CommentHistory', dependent: :restrict_with_error

  validates :current_version_no, presence: true, numericality: { only_integer: true, greater_than: 0 }

  counter_culture :topic, column_name: 'total_comment'

  before_validation :set_initial_version, on: :create
  after_create :create_history

  def update_content!(content)
    return if will_save_change_to_content?

    with_lock do
      next_version_no = current_version_no + 1
      update!(content: content, current_version_no: next_version_no)
      histories.create!(
        topic: topic,
        author: author,
        content: content,
        version_no: next_version_no
      )
    end
  end

  def apply_decision!(decision)
    hide_by_decision!(decision)
  end

  def hide_by_decision!(decision)
    update!(
      hidden: true,
      hidden_cause_decision: decision
    )
  end

  def invisible?
    hidden? || author.suspended?
  end

  private

  def set_initial_version
    self.current_version_no ||= 1
  end

  def create_history
    histories.create!(
      topic: topic,
      author: author,
      content: content,
      version_no: current_version_no
    )
  end
end
