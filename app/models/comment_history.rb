# frozen_string_literal: true

class CommentHistory < ApplicationRecord
  belongs_to :comment
  belongs_to :topic
  belongs_to :author, class_name: 'User'

  validates :content, presence: true, length: { maximum: 5000 }
  validates :version_no, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
