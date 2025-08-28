# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :actor, :record

  def initialize(actor, record)
    @actor = actor
    @record = record
  end

  def index? = false
  def show? = false
  def new? = false
  def edit? = false
  def create? = false
  def update? = false
  def destroy? = false

  private

  def logged_in? = !!actor
  def user? = actor.is_a?(User)
  def moderator? = actor.is_a?(Moderator)

  def owner?
    user? && record.author_id == actor.id
  end
end
