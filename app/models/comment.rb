# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'User'

  validates :content, presence: true
  validates :current_version_no, presence: true
end
