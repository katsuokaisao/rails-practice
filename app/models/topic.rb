# frozen_string_literal: true

# トピックモデル
# 掲示板に集まって人で話し合うためのテーマやトピックのこと
# == Schema Information
#
# Table name: topics
#
#  id            :bigint           not null, primary key
#  title         :string(255)      not null
#  total_comment :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  author_id     :bigint           not null
#
# Indexes
#
#  idx_topics_author_id   (author_id)
#  idx_topics_created_at  (created_at)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#
class Topic < ApplicationRecord
  belongs_to :author, class_name: 'User'
  has_many :comments, dependent: :restrict_with_exception, inverse_of: :topic
  validates :title, length: { minimum: 1, maximum: 120 }, no_html: true
end
