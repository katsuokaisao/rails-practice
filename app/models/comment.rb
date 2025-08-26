# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'User'
  has_many :histories, class_name: 'CommentHistory', dependent: :restrict_with_error

  validates :content, presence: true
  validates :current_version_no, presence: true
end
