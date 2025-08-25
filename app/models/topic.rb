# frozen_string_literal: true

# トピックモデル
# 掲示板に集まって人で話し合うためのテーマやトピックのこと
class Topic < ApplicationRecord
  belongs_to :author, class_name: 'User'
  validates :title, length: { minimum: 1, maximum: 120 }
end
