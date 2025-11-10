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
    puts 'Topics sample'
    Topic.take(10).each do |topic|
      puts "Topic: #{topic.title}, Author: #{topic.author.login_id}"
    end
  end

  def puts_comments
    puts 'Comments sample'
    Comment.take(10).each do |comment|
      puts "Topic: #{comment.topic.title}, Author: #{comment.author.login_id}, Comment: #{comment.content}"
    end
  end

  def puts_comment_histories
    puts 'Comment Histories sample'
    CommentHistory.take(10).each do |comment_history|
      puts <<~MSG
        Comment: #{comment_history.comment.content},
        Author: #{comment_history.author.login_id},
        Version: #{comment_history.version_no}
      MSG
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
