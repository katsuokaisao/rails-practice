# frozen_string_literal: true

class SampleCreator
  class << self
    delegate :create, to: :new
  end

  def create
    create_users
    create_moderators
    create_topics
    create_comments
    update_comments
    put_records
  end

  private

  def create_moderators
    FactoryBot.create_list(:moderator, 3)
  end

  def create_users
    FactoryBot.create_list(:user, 10)
  end

  def create_topics
    users = User.all.to_a
    200.times do
      FactoryBot.create(:topic, title: Faker::Book.title, author: users.sample)
    end
  end

  def create_comments
    topics = Topic.order(created_at: :desc).limit(10)
    users = User.all.to_a
    topics.each do |topic|
      100.times do
        Comment.create_with_history!(
          topic: topic,
          author: users.sample,
          content: Faker::Lorem.paragraphs(number: 3).join("\n")
        )
      end
    end
  end

  def update_comments
    Comment.first(100).each do |comment|
      10.times do
        comment.update_content!(Faker::Lorem.paragraphs(number: 3).join("\n"))
      end
    end
  end

  def put_records
    puts_users
    puts_moderators
    puts_topics
    puts_comments
    puts_comment_histories
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
    puts 'Topics sample'
    Topic.take(10).each do |topic|
      puts "Topic: #{topic.title}, Author: #{topic.author.nickname}"
    end
  end

  def puts_comments
    puts 'Comments sample'
    Comment.take(10).each do |comment|
      puts "Topic: #{comment.topic.title}, Author: #{comment.author.nickname}, Comment: #{comment.content}"
    end
  end

  def puts_comment_histories
    puts 'Comment Histories sample'
    CommentHistory.take(10).each do |comment_history|
      puts <<~MSG
        Comment: #{comment_history.comment.content},
        Author: #{comment_history.author.nickname},
        Version: #{comment_history.version_no}
      MSG
    end
  end
end
