# frozen_string_literal: true

class SampleCreator
  class << self
    delegate :create, to: :new
  end

  def create
    create_users
    create_moderators
    create_topics
    put_records
  end

  private

  def create_moderators
    FactoryBot.create_list(:moderator, 3)
  end

  def create_users
    FactoryBot.create_list(:user, 3)
  end

  def create_topics
    users = User.all.to_a
    200.times do
      FactoryBot.create(:topic, title: Faker::Book.title, author: users.sample)
    end
  end

  def put_records
    puts_users
    puts_moderators
    puts_topics
  end

  def puts_users
    User.find_each do |user|
      puts "User: #{user.nickname}"
    end
  end

  def puts_moderators
    Moderator.find_each do |moderator|
      puts "Moderator: #{moderator.nickname}"
    end
  end

  def puts_topics
    Topic.find_each do |topic|
      puts "Topic: #{topic.title}, Author: #{topic.author.nickname}"
    end
  end
end
