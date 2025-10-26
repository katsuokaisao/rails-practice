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
    tenants_data = [
      {
        name: '社内フォーラム',
        identifier: 'company-forum',
        description: '社員向けの情報共有・質問・議論のための掲示板です。'
      },
      {
        name: 'アイドルファンコミュニティ',
        identifier: 'idol-community',
        description: 'アイドルファンが集まるコミュニティ掲示板です。'
      },
      {
        name: 'ゲーム攻略掲示板',
        identifier: 'game-strategy',
        description: 'ゲームの攻略情報を共有する掲示板です。'
      },
      {
        name: 'プログラミング学習',
        identifier: 'programming-study',
        description: 'プログラミング学習者のための質問・共有掲示板です。'
      }
    ]

    tenants_data.each do |data|
      Tenant.create!(
        name: data[:name],
        identifier: data[:identifier],
        description: data[:description]
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

    # 日本語の表示名候補
    display_names = %w[
      山田太郎 鈴木花子 田中一郎 佐藤美咲 高橋健太
      渡辺優子 伊藤大輔 中村舞 小林拓也 加藤愛
      吉田悠太 山本さくら 佐々木隼人 松本美優 井上翔
      木村結衣 林雄大 斉藤琴音 清水陽介 森本彩花
      たろちゃん はなちゃん けんけん まいまい ゆうちゃん
      taro_y hanako_s ken_t mai_n yuta_y
    ]

    # 各テナントに10〜15人のメンバーを追加
    tenants.each do |tenant|
      member_count = rand(10..15)
      selected_users = users.sample(member_count)
      used_names = []

      selected_users.each do |user|
        # このテナント内で未使用の表示名を選択
        available_names = display_names - used_names
        display_name = available_names.sample || "ユーザー#{rand(1000..9999)}"

        TenantMembership.create!(
          tenant: tenant,
          user: user,
          display_name: display_name
        )

        used_names << display_name
      end
    end

    # 一部のユーザーは複数のテナントに所属させる
    multi_tenant_users = users.sample(10)
    multi_tenant_users.each do |user|
      # 既に所属しているテナント以外から1〜2個選択
      current_tenant_ids = user.tenant_memberships.pluck(:tenant_id)
      available_tenants = tenants.reject { |t| current_tenant_ids.include?(t.id) }

      next if available_tenants.empty?

      additional_tenant_count = rand(1..2)
      selected_tenants = available_tenants.sample(additional_tenant_count)

      selected_tenants.each do |tenant|
        # このテナント内で未使用の表示名を選択
        used_names = TenantMembership.where(tenant: tenant).pluck(:display_name)
        available_names = display_names - used_names
        display_name = available_names.sample || "ユーザー#{rand(1000..9999)}"

        TenantMembership.create!(
          tenant: tenant,
          user: user,
          display_name: display_name
        )
      end
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
    puts_tenants
    puts_users
    puts_tenant_memberships
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
      puts "User: #{user.nickname}, Suspended: #{user.suspended? ? 'Yes' : 'No'}"
    end
  end

  def puts_tenant_memberships
    puts 'Tenant Memberships'
    Tenant.includes(tenant_memberships: :user).find_each do |tenant|
      puts "テナント: #{tenant.name}"
      tenant.tenant_memberships.each do |membership|
        puts "  - #{membership.display_name} (#{membership.user.nickname})"
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
      puts "ユーザー: #{user.nickname}"
      user.tenant_memberships.each do |membership|
        puts "  - #{membership.tenant.name}: #{membership.display_name}"
      end
      puts ''
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
