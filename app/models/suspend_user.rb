# frozen_string_literal: true

# == Schema Information
#
# Table name: suspend_users
#
#  id              :bigint           not null, primary key
#  suspended_until :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :bigint           not null
#
# Indexes
#
#  idx_suspend_users_user_id  (user_id) UNIQUE
#
class SuspendUser < ApplicationRecord
  belongs_to :user
  validates :suspended_until, presence: true
end
