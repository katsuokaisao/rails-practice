# frozen_string_literal: true

class SampleCreator
  def self.create
    new.create
  end

  def create
    create_tenants
    create_users
    create_suspend_users
    create_tenant_memberships
    create_tenant_invitations
    create_moderators
    create_topics
    create_comments
    update_comments
    create_reports
    create_decisions
    put_records
  end

  private

  def create_tenants
    200.times do |i|
      Tenant.create!(
        name: Faker::Company.name,
        identifier: "tenant-#{i + 1}-#{SecureRandom.hex(3)}",
        description: Faker::Lorem.sentence(word_count: 10)
      )
    end
  end

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

  def create_tenant_memberships
    tenants = Tenant.all.to_a
    users = User.all.to_a

    # 各ユーザーをランダムに複数のテナントに所属させる
    users.each do |user|
      # ユーザーごとに5〜30個のテナントに所属
      membership_count = rand(5..30)
      selected_tenants = tenants.sample(membership_count)

      selected_tenants.each do |tenant|
        used_names = TenantMembership.where(tenant: tenant).pluck(:display_name)
        display_name = generate_unique_display_name(used_names)

        TenantMembership.create!(
          tenant: tenant,
          user: user,
          display_name: display_name
        )
      end
    end
  end

  def generate_unique_display_name(used_names)
    loop do
      name = Faker::Japanese::Name.name
      return name unless used_names.include?(name)
    end
  end

  def create_topics
    tenants = Tenant.order(created_at: :desc).limit(50).to_a
    puts "Creating topics for #{tenants.count} tenants..."

    total_topics = 0

    tenants.each do |tenant|
      members = tenant.members.to_a

      if members.empty?
        puts "  ⚠️  Tenant '#{tenant.name}' has no members, skipping..."
        next
      end

      topic_count = rand(20..30)

      topic_count.times do
        created_at = rand(60.days.ago..Time.current)

        Topic.create!(
          tenant: tenant,
          author: members.sample,
          title: Faker::Book.title,
          created_at: created_at,
          updated_at: created_at
        )

        total_topics += 1
      end

      print '.'
    end

    puts "\n✅ Created #{total_topics} topics across #{tenants.count} tenants"
  end

  def create_comments
    tenants = Tenant.order(created_at: :desc).limit(50).to_a
    puts "Creating comments for latest topics in #{tenants.count} tenants..."

    total_comments = 0
    total_topics = 0

    tenants.each do |tenant|
      topics = tenant.topics.order(created_at: :desc).limit(10).to_a
      members = tenant.members.to_a

      if members.empty?
        puts "  ⚠️  Tenant '#{tenant.name}' has no members, skipping..."
        next
      end

      if topics.empty?
        puts "  ⚠️  Tenant '#{tenant.name}' has no topics, skipping..."
        next
      end

      comments, topics_count = create_comments_for_topics(topics, members)
      total_comments += comments
      total_topics += topics_count

      print '.'
    end

    puts "\n✅ Created #{total_comments} comments for #{total_topics} topics in #{tenants.count} tenants"
  end

  def create_comments_for_topics(topics, members)
    comments_count = 0
    topics_count = 0

    topics.each do |topic|
      comment_count = rand(20..50)

      comment_count.times do
        created_at = rand(topic.created_at..Time.current)

        topic.comments.create!(
          author: members.sample,
          content: Faker::Lorem.paragraphs(number: rand(1..3)).join("\n"),
          created_at: created_at,
          updated_at: created_at
        )

        comments_count += 1
      end

      topics_count += 1
    end

    [comments_count, topics_count]
  end

  def update_comments
    puts 'Updating comments to create histories...'

    Comment.order('RAND()').limit(100).each do |comment|
      10.times do
        comment.update_content!(Faker::Lorem.paragraphs(number: rand(1..3)).join("\n"))
      end

      print '.'
    end

    puts "\n✅ Updated 100 comments (created ~1000 comment histories)"
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

  def create_tenant_invitations
    tenants = Tenant.all.to_a
    users = User.all.to_a

    tenants.each do |tenant|
      invitation_count = rand(3..5)
      members = tenant.members.to_a
      non_members = users - members

      next if members.empty? || non_members.empty?

      invite_users = non_members.first(invitation_count)

      invitation_count.times do |i|
        inviter = members.sample
        invited_user = invite_users[i]

        TenantInvitation.create!(
          tenant: tenant,
          inviter: inviter,
          invited_user: invited_user,
          status: :pending
        )
      end
    end
  end

  def put_records
    puts_tenants
    puts_users
    puts_tenant_memberships
    puts_tenant_invitations
    puts_moderators
    puts_topics
    puts_comments
    puts_comment_histories
    puts_reports
    puts_decisions
  end

  def puts_tenants
    puts 'Tenants'
    Tenant.find_each do |tenant|
      puts "Tenant: #{tenant.name} (@#{tenant.identifier})}"
    end
  end

  def puts_users
    User.find_each do |user|
      puts "User: #{user.login_id}, Suspended: #{user.suspended? ? 'Yes' : 'No'}"
    end
  end

  def puts_tenant_memberships
    puts 'Tenant Memberships'
    Tenant.includes(tenant_memberships: :user).find_each do |tenant|
      puts "テナント: #{tenant.name}"
      tenant.tenant_memberships.each do |membership|
        puts "  - #{membership.display_name} (#{membership.user.login_id})"
      end
      puts "  合計: #{tenant.tenant_memberships.count}人"
      puts ''
    end

    # マルチテナント所属ユーザーの表示
    puts 'マルチテナント所属ユーザー'
    User.joins(:tenant_memberships)
        .group('users.id')
        .having('COUNT(tenant_memberships.id) > 1')
        .includes(tenant_memberships: :tenant)
        .find_each do |user|
      puts "ユーザー: #{user.login_id}"
      user.tenant_memberships.each do |membership|
        puts "  - #{membership.tenant.name}: #{membership.display_name}"
      end
      puts ''
    end
  end

  def puts_moderators
    Moderator.find_each do |moderator|
      puts "Moderator: #{moderator.login_id}"
    end
  end

  def puts_topics
    puts "\n#{'=' * 50}"
    puts 'Topics sample (showing 10 topics)'
    puts '=' * 50

    Topic.includes(:tenant, :author).order('RAND()').limit(10).each do |topic|
      puts "📌 Tenant: #{topic.tenant.name} (@#{topic.tenant.identifier})"
      puts "   Title: #{topic.title}"
      puts "   Author: #{topic.author.login_id}"
      puts "   Comments: #{topic.total_comment}"
      puts "   Created: #{topic.created_at.strftime('%Y-%m-%d %H:%M')}"
      puts ''
    end
  end

  def puts_comments
    puts "\n#{'=' * 50}"
    puts 'Comments sample (showing 10 comments)'
    puts '=' * 50

    Comment.includes(:topic, :author).order('RAND()').limit(10).each do |comment|
      puts "   Topic: #{comment.topic.title}"
      puts "   Author: #{comment.author.login_id}"
      puts "   Content: #{comment.content.truncate(100)}"
      puts "   Version: #{comment.current_version_no}"
      puts "   Created: #{comment.created_at.strftime('%Y-%m-%d %H:%M')}"
      puts ''
    end
  end

  def puts_comment_histories
    puts "\n#{'=' * 50}"
    puts 'Comment Histories sample (showing 10 histories)'
    puts '=' * 50

    CommentHistory.includes(:comment, :author).order('RAND()').limit(10).each do |history|
      puts "   Comment ID: #{history.comment.id}"
      puts "   Author: #{history.author.login_id}"
      puts "   Version: #{history.version_no}"
      puts "   Content: #{history.content.truncate(100)}"
      puts "   Created: #{history.created_at.strftime('%Y-%m-%d %H:%M')}"
      puts ''
    end
  end

  def puts_reports
    puts 'Reports sample'
    Report.take(10).each do |report|
      puts <<~MSG
        Reporter: #{report.reporter.login_id},
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
        Decided By: #{decision.decider.login_id},
        Decision Type: #{decision.decision_type},
        Note: #{decision.note}
      MSG
    end
  end

  def puts_tenant_invitations
    puts 'Tenant Invitations'
    Tenant.includes(tenant_invitations: %i[inviter invited_user]).find_each do |tenant|
      invitations = tenant.tenant_invitations
      next if invitations.empty?

      puts "テナント: #{tenant.name}"
      puts "  招待数: #{invitations.count}件"
      invitations.first(3).each do |invitation|
        puts "    - #{invitation.inviter.login_id} → #{invitation.invited_user.login_id} [#{invitation.status}]"
      end
      puts ''
    end
  end
end
