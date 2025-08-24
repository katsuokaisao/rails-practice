# frozen_string_literal: true

class SampleCreator
  class << self
    def create
      new.create
    end
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
    puts '=== Users ==='
    User.all.each do |user|
      puts "User: #{user.nickname}"
    end

    puts "\n=== Moderators ==="
    Moderator.all.each do |moderator|
      puts "Moderator: #{moderator.nickname}"
    end
  end
end
