# frozen_string_literal: true

# トピックモデル
# 掲示板に集まって人で話し合うためのテーマやトピックのこと
class Topic < ApplicationRecord
  belongs_to :author, class_name: 'User'
  has_many :comments, dependent: :restrict_with_exception, inverse_of: :topic
  validates :title, length: { minimum: 1, maximum: 120 }, no_html: true

  def increment_total_comment!
    increment(:total_comment, 1).save!
  end
end
