# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'User'
  has_many :histories, class_name: 'CommentHistory', dependent: :restrict_with_error

  validates :content, presence: true
  validates :current_version_no, presence: true

  after_create :create_history
  after_update :create_history

  private

  def create_history
    histories.create!(
      topic: topic,
      author: author,
      content: content,
      version_no: current_version_no
    )
  end
end
