# frozen_string_literal: true

module CommentSharedBehavior
  extend ActiveSupport::Concern

  included do
    belongs_to :topic
    belongs_to :author, class_name: 'User'

    validates :content, presence: true, length: { maximum: 5000 }
  end
end
