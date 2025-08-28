# frozen_string_literal: true

class TopicsPolicy < ApplicationPolicy
  def index? = true
  def show? = true
  def new? = user?
  def create? = user?
  def edit? = user? && owner?
  def update? = user? && owner?
end
