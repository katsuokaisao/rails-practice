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
    put_users_and_moderators
  end

  private

  def create_moderators
    FactoryBot.create_list(:moderator, 3)
  end

  def create_users
    FactoryBot.create_list(:user, 3)
  end

  def put_users_and_moderators
    puts '=== Users ==='
    User.find_each do |user|
      puts "User: #{user.nickname}"
    end

    puts "=== Moderators ==="
    Moderator.find_each do |moderator|
      puts "Moderator: #{moderator.nickname}"
    end
  end
end
