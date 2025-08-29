# frozen_string_literal: true

class SampleCreator
  class << self
    delegate :create, to: :new
  end

  def create
    create_users
    create_suspend_users
    create_moderators
    create_topics
    create_comments
    update_comments
    create_reports
    create_decisions
    put_records
  end

  private

  def create_moderators
    FactoryBot.create_list(:moderator, 3)
  end

  def create_users
    FactoryBot.create_list(:user, 10)
  end

  def create_suspend_users
    User.last(3).each do |user|
      FactoryBot.create(:suspend_user, user: user)
    end
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

  def create_reports
    comments = Comment.eager_load(:author).to_a
    users = User.find_each.to_a
    100.times do
      type = %w[comment user].sample
      case type
      when 'comment'
        reporter = users.sample
        comment = comments.sample
        next if comment.author == reporter

        FactoryBot.create(:report, :for_comment, reporter: reporter, target_comment: comment)
      when 'user'
        reporter, target = users.sample(2)
        FactoryBot.create(:report, :for_user, reporter: reporter, target_user: target)
      end
    end
  end

  def create_decisions
    reports = Report.order(created_at: :asc).limit(20)
    moderators = Moderator.all.to_a
    reports.each do |report|
      moderator = moderators.sample
      FactoryBot.create(:decision, report: report, moderator: moderator)
    end
  end

  def put_records
    puts_users
    puts_suspend_users
    puts_moderators
    puts_topics
    puts_comments
    puts_comment_histories
    puts_reports
    puts_decisions
  end

  def puts_users
    User.find_each do |user|
      puts "User: #{user.nickname}"
    end
  end

  def puts_suspend_users
    SuspendUser.find_each do |suspend_user|
      puts "SuspendUser: #{suspend_user.user.nickname}, Suspended Until: #{suspend_user.suspended_until}"
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

  def puts_reports
    puts 'Reports sample'
    Report.take(10).each do |report|
      puts <<~MSG
        Reporter: #{report.reporter.nickname},
        Target Type: #{report.target_type},
        Reason Type: #{report.reason_type},
        Reason Text: #{report.reason_text}
      MSG
    end
  end

  def puts_decisions
    puts 'Decisions sample'
    Decision.take(10).each do |decision|
      puts <<~MSG
        Report: #{decision.report.id},
        Decided By: #{decision.moderator.nickname},
        Decision Type: #{decision.decision_type},
        Note: #{decision.note}
      MSG
    end
  end
end
