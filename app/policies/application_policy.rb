# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :moderator, :tenant, :record

  def initialize(user, moderator, tenant, record)
    @user = user
    @moderator = moderator
    @tenant = tenant
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
  def only_user? = !!user && !moderator?
  def only_moderator? = !!moderator && !user?

  def owner?
    return false unless user?

    return record.author == user if record.respond_to?(:author)
    return report_owner?(record) if record.is_a?(Report)

    false
  end

  def report_owner?(report)
    return report.reportable&.author == user if report.reportable_type_comment?
    return report.reportable == user if report.reportable_type_user?

    false
  end

  def tenant_member?
    return false unless user? && tenant

    user.member_of?(tenant)
  end

  def membership_owner?
    return false unless user? && tenant && record.is_a?(TenantMembership)

    record.user == user && record.tenant == tenant
  end
end
