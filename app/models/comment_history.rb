# frozen_string_literal: true

class CommentHistory < ApplicationRecord
  belongs_to :comment
  belongs_to :topic
  belongs_to :author, class_name: 'User'

  validates :content, presence: true
  validates :version_no, presence: true
end
