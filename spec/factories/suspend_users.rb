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
FactoryBot.define do
  factory :suspend_user do
    association :user
    suspended_until { 1.day.from_now }
  end
end
