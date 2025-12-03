# frozen_string_literal: true

class SampleCreator
  def self.create
    new.create
  end

  def create
    create_tenants
    create_users
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
    puts 'Creating tenants...'
    200.times do |i|
      Tenant.create!(
        name: Faker::Company.name,
        slug: "tenant-#{i + 1}-#{SecureRandom.hex(3)}",
        description: Faker::Lorem.sentence(word_count: 10)
      )
    end
  end

  def create_users
    puts 'Creating users...'
    FactoryBot.create_list(:user, 20)
  end

  def create_tenant_memberships
    puts 'Creating tenant memberships...'
    tenants = Tenant.order(created_at: :desc).limit(20).to_a
    users = User.all.to_a

    users.each do |user|
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

  def create_tenant_invitations
    puts 'Creating tenant invitations...'
    tenants = Tenant.all.to_a
    users = User.all.to_a

    tenants.each do |tenant|
      members = tenant.members.to_a
      non_members = users - members

      next if members.empty? || non_members.empty?

      invitation_count = [rand(3..5), non_members.count].min
      invite_users = non_members.sample(invitation_count)

      invite_users.each do |invited_user|
        inviter = members.sample

        TenantInvitation.create!(
          tenant: tenant,
          inviter: inviter,
          invited_user: invited_user,
          status: :pending
        )
      end
    end
  end

  def create_moderators
    puts 'Creating moderators...'
    Tenant.order(created_at: :desc).limit(20).each do |tenant|
      3.times do |i|
        Moderator.create!(
          login_id: "#{tenant.slug}_#{i + 1}",
          password: 'password',
          tenant: tenant
        )
      end
    end
  end

  def create_topics
    puts 'Creating topics...'
    tenants = Tenant.order(created_at: :desc).limit(20).to_a
    tenants.each do |tenant|
      members = tenant.members.to_a

      if members.empty?
        puts "  ⚠️  Tenant '#{tenant.name}' has no members, skipping..."
        next
      end

      topic_count = rand(20..30)

      topic_count.times do
        created_at = rand(60.days.ago..Time.current)

        tenant.topics.create!(
          author: members.sample,
          title: Faker::Book.title,
          created_at: created_at,
          updated_at: created_at
        )
      end
    end
  end

  def create_comments
    puts 'Creating comments...'
    tenants = Tenant.order(created_at: :desc).limit(20).to_a
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

      create_comments_for_topics(topics, members)
    end
  end

  def create_comments_for_topics(topics, members)
    topics.each do |topic|
      comment_count = rand(20..30)

      comment_count.times do
        created_at = rand(topic.created_at..Time.current)

        topic.comments.create!(
          author: members.sample,
          content: Faker::Lorem.paragraphs(number: rand(1..3)).join("\n"),
          created_at: created_at,
          updated_at: created_at
        )
      end
    end
  end

  def update_comments
    puts 'Updating comments...'
    Comment.order('RAND()').limit(100).each do |comment|
      10.times do
        comment.update_content!(Faker::Lorem.paragraphs(number: rand(1..3)).join("\n"))
      end
    end
  end

  def create_reports
    puts 'Creating reports...'
    tenants = Tenant.order(created_at: :desc).limit(20).to_a
    tenants.each do |tenant|
      create_reports_for_tenant(tenant)
    end
  end

  def create_reports_for_tenant(tenant)
    members = tenant.members.to_a
    topics = tenant.topics.includes(:comments)

    if members.empty?
      puts "  ⚠️  Tenant '#{tenant.name}' has no members, skipping..."
      return 0
    end

    if topics.empty?
      puts "  ⚠️  Tenant '#{tenant.name}' has no topics, skipping..."
      return 0
    end

    report_count = rand(10..20)

    report_count.times do
      type = %w[Comment User].sample
      case type
      when 'Comment'
        try_create_comment_report(tenant, members, topics)
      when 'User'
        try_create_user_report(tenant, members)
      end
    end
  end

  def try_create_comment_report(tenant, members, topics)
    topic = topics.sample
    if topic.comments.empty?
      puts "  ⚠️  Topic '#{topic.title}' has no comments, skipping..."
      return
    end

    comment = topic.comments.sample
    reporter = members.reject { |m| m == comment.author }.sample
    if reporter.nil?
      puts "  ⚠️  No valid reporter found for comment ID #{comment.id}, skipping..."
      return false
    end

    Report.create!(
      tenant: tenant,
      reporter: reporter,
      reportable: comment,
      ban_reason: tenant.ban_reasons.active_reasons.sample,
      reason_text: Faker::Lorem.sentence(word_count: 10)
    )
  end

  def try_create_user_report(tenant, members)
    reporter, reportable_user = members.sample(2)
    if reporter.nil? || reportable_user.nil?
      puts "  ⚠️  Not enough members to create user report in tenant '#{tenant.name}', skipping..."
      return false
    end

    if reporter == reportable_user
      puts "  ⚠️  Reporter and reportable user are the same for tenant '#{tenant.name}', skipping..."
      return false
    end

    Report.create!(
      tenant: tenant,
      reporter: reporter,
      reportable: reportable_user,
      ban_reason: tenant.ban_reasons.active_reasons.sample,
      reason_text: Faker::Lorem.sentence(word_count: 10)
    )
  end

  def create_decisions
    puts 'Creating decisions...'
    Tenant.order(created_at: :desc).limit(20).each do |tenant|
      create_decisions_for_tenant(tenant)
    end
  end

  def create_decisions_for_tenant(tenant)
    moderators = tenant.moderators.to_a
    reports = tenant.reports.where.missing(:decision).to_a

    if moderators.empty?
      puts "  ⚠️  Tenant '#{tenant.name}' has no moderators, skipping..."
      return
    end

    if reports.empty?
      puts "  ⚠️  Tenant '#{tenant.name}' has no reports (or all reports already have decisions), skipping..."
      return
    end

    reports_to_decide = reports.sample([3, reports.count].min)

    reports_to_decide.each do |report|
      # 類似レポートの自動決定により既にdecisionが作成されている可能性があるため再読み込み
      report.reload
      next if report.decision.present?

      create_decision(tenant, report, moderators.sample)
    end
  end

  def create_decision(tenant, report, moderator)
    decision_type = determine_decision_type(report)

    Decision.create!(
      tenant: tenant,
      report: report,
      decider: moderator,
      decision_type: decision_type,
      note: Faker::Lorem.sentence(word_count: 5),
      suspended_until: decision_type == 'suspend_user' ? rand(7..30).days.from_now : nil
    )
  end

  def determine_decision_type(report)
    case report.reportable_type
    when 'Comment'
      %w[reject hide_comment].sample
    when 'User'
      %w[reject suspend_user].sample
    else
      'reject'
    end
  end

  def generate_unique_display_name(used_names)
    loop do
      name = Faker::Japanese::Name.name
      return name unless used_names.include?(name)
    end
  end

  def put_records
    puts_sample_tenants
    puts_sample_users
    puts_sample_topics
    puts_sample_comments
    puts_sample_reports
    puts_sample_decisions
  end

  def puts_sample_tenants
    puts "\nTenants (showing 5):"
    Tenant.order(created_at: :desc).limit(5).each do |tenant|
      member_count = tenant.tenant_memberships.count
      topic_count = tenant.topics.count
      puts "  - #{tenant.name} (@#{tenant.slug})"
      puts "    Members: #{member_count}, Topics: #{topic_count}"
    end
  end

  def puts_sample_users
    puts "\nUsers (showing 5):"
    User.includes(:tenant_memberships).limit(5).each do |user|
      membership_count = user.tenant_memberships.count
      suspended_count = user.tenant_memberships.select(&:suspended?).count
      status = suspended_count.positive? ? " (suspended in #{suspended_count} tenants)" : ''
      puts "  - #{user.login_id}: #{membership_count} memberships#{status}"
    end
  end

  def puts_sample_topics
    puts "\nTopics (showing 5):"
    Topic.includes(:tenant, :author).order('RAND()').limit(5).each do |topic|
      puts "  - \"#{topic.title}\" by #{topic.author.login_id}"
      puts "    Tenant: #{topic.tenant.name}, Comments: #{topic.total_comment}"
    end
  end

  def puts_sample_comments
    puts "\nComments (showing 5):"
    Comment.includes(:topic, :author).order('RAND()').limit(5).each do |comment|
      puts "  - #{comment.author.login_id} on \"#{comment.topic.title}\""
      puts "    Content: #{comment.content.truncate(60)}, Version: #{comment.current_version_no}"
    end
  end

  def puts_sample_reports
    puts "\nReports (showing 5):"
    Report.includes(:tenant, :reporter, :reportable, :ban_reason).order('RAND()').limit(5).each do |report|
      status = report.reviewed? ? 'reviewed' : 'pending'
      puts "  - #{report.reportable_type} report by #{report.reporter.login_id}"
      puts "    Tenant: #{report.tenant.name}, Reason: #{report.ban_reason.name}, Status: #{status}"
    end
  end

  def puts_sample_decisions
    puts "\nDecisions (showing 5):"
    Decision.includes(:tenant, :decider, :report).order('RAND()').limit(5).each do |decision|
      puts "  - #{decision.decision_type} by #{decision.decider.login_id}"
      puts "    Tenant: #{decision.tenant.name}, Report: #{decision.report.reportable_type}"
    end
  end

  def puts_record_count
    puts "Tenants: #{Tenant.count}"
    puts "Users: #{User.count}"
    puts "Tenant Memberships: #{TenantMembership.count}"
    puts "Tenant Invitations: #{TenantInvitation.count}"
    puts "Moderators: #{Moderator.count}"
    puts "Topics: #{Topic.count}"
    puts "Comments: #{Comment.count}"
    puts "Comment Histories: #{CommentHistory.count}"
    puts "Reports: #{Report.count}"
    puts "Decisions: #{Decision.count}"
  end
end
