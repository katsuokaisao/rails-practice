# frozen_string_literal: true

class SampleCreator
  def self.create
    new.create
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
    FactoryBot.create_list(:moderator, 5)
  end

  def create_users
    FactoryBot.create_list(:user, 20)
  end

  def create_suspend_users
    5.times do
      FactoryBot.create(:user, :suspended)
    end
  end

  def create_topics
    users = User.all.to_a
    200.times do
      FactoryBot.create(:topic, title: Faker::Book.title, author: users.sample)
    end
  end

  def create_comments
    topics = Topic.order(created_at: :desc).limit(20)
    users = User.all.to_a
    topics.each do |topic|
      300.times do
        Comment.create!(
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
    users = User.where(suspended_until: nil).last(5)
    500.times do
      type = %w[Comment User].sample
      case type
      when 'Comment'
        reporter = users.sample
        comment = comments.sample
        next if comment.author == reporter

        FactoryBot.create(:report, :for_comment, reporter: reporter, reportable: comment)
      when 'User'
        reporter, reportable_user = users.sample(2)
        FactoryBot.create(:report, :for_user, reporter: reporter, reportable: reportable_user)
      end
    end
  end

  def create_decisions
    reports = Report.order(created_at: :asc).limit(200)
    moderators = Moderator.all.to_a

    reports.each do |report|
      moderator = moderators.sample
      next if report.reload.reviewed?

      FactoryBot.create(:decision, report: report, decider: moderator)
    end
  end

  def put_records
    puts_users
    puts_moderators
    puts_topics
    puts_comments
    puts_comment_histories
    puts_reports
    puts_decisions
  end

  def puts_users
    User.find_each do |user|
      puts "User: #{user.nickname}, Suspended: #{user.suspended? ? 'Yes' : 'No'}"
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
        Reportable Type: #{report.reportable_type},
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
        Decided By: #{decision.decider.nickname},
        Decision Type: #{decision.decision_type},
        Note: #{decision.note}
      MSG
    end
  end
end
