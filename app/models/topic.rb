# frozen_string_literal: true

# トピックモデル
# 掲示板に集まって人で話し合うためのテーマやトピックのこと
# == Schema Information
#
# Table name: topics
#
#  id            :bigint           not null, primary key
#  locked_at     :datetime
#  title         :string(255)      not null
#  total_comment :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  author_id     :bigint           not null
#  tenant_id     :bigint           not null
#
# Indexes
#
#  idx_topics_author_id             (author_id)
#  idx_topics_tenant_id_created_at  (tenant_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (tenant_id => tenants.id)
#
class Topic < ApplicationRecord
  belongs_to :tenant
  belongs_to :author, class_name: 'User'
  has_many :comments, dependent: :destroy, inverse_of: :topic
  validates :title, length: { minimum: 1, maximum: 120 }, no_html: true

  scope :locked, -> { where.not(locked_at: nil) }
  scope :unlocked, -> { where(locked_at: nil) }

  def locked?
    locked_at.present?
  end

  def lock!
    update!(locked_at: Time.current) unless locked?
  end

  def unlock!
    update!(locked_at: nil) if locked?
  end

  def self.delete_with_dependencies(topic_ids)
    return if topic_ids.empty?

    comment_ids = Comment.where(topic_id: topic_ids).pluck(:id)
    Comment.delete_with_dependencies(comment_ids) if comment_ids.any?

    where(id: topic_ids).delete_all
  end
end
