# frozen_string_literal: true

# サンプルデータ作成クラス
#
# 開発用のサンプルデータを作成する。
class SampleCreator
  class << self
    delegate :create, to: :new
  end

  def create
    create_users
    create_moderators
    put_all_accounts
  end

  private

  def create_moderators
    3.times do |i|
      create_moderator("moderator#{i + 1}")
    end
  end

  def create_moderator(nickname)
    Moderator.find_or_create_by(nickname: nickname) do |moderator|
      moderator.password = 'password'
      moderator.password_confirmation = 'password'
    end
  end

  def create_users
    3.times do |i|
      create_user("test#{i + 1}")
    end
  end

  def create_user(nickname)
    User.find_or_create_by(nickname: nickname) do |user|
      user.password = 'password'
      user.password_confirmation = 'password'
    end
  end

  def put_all_accounts
    Rails.logger.debug '=== Users ==='
    User.find_each do |user|
      Rails.logger.debug "User: #{user.nickname}"
    end

    Rails.logger.debug "\n=== Moderators ==="
    Moderator.find_each do |moderator|
      Rails.logger.debug "Moderator: #{moderator.nickname}"
    end
  end
end
