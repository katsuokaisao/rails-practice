# frozen_string_literal: true

class SuspendUser < ApplicationRecord
  belongs_to :user
  validates :suspended_until, presence: true
end
