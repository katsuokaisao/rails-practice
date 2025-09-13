# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :moderator, :record

  def initialize(user, moderator, record)
    @user = user
    @moderator = moderator
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

  # user と moderator は同時ログイン可能。
  # 同時ログイン時は、現在のリクエストが user 由来か moderator 由来かは区別できない。
  # 同時ログインしている場合は、両ロールの権限をすべて付与する方針で基本的に良いと思う（＝最大権限）。
  # 同時ログインを許容しない場合は、only_user? または only_moderator? を利用して制御する。
  # 基本的に同時ログインはしないようにするという運用で良いと思う
  def logged_in? = !!user || !!moderator
  def user? = !!user
  def moderator? = !!moderator
  def unsuspended_user? = user? && !user.suspended?
  def owner? = user? && record.author_id == user.id
  def only_user? = !!user && !moderator?
  def only_moderator? = !!moderator && !user?
end
