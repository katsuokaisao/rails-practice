class SampleCreator
  class << self
    def create
      self.new.create
    end
  end

  def create
    create_users()
    create_moderators()
    put_users()
  end

  private

  def create_moderators
    3.times do |i|
      create_moderator("moderator#{i + 1}")
    end
  end

  def create_moderator(nickname)
    User.find_or_create_by(nickname: nickname) do |user|
      user.password = "password"
      user.password_confirmation = "password"
      user.role = :moderator
    end
  end

  def create_users
    3.times do |i|
      create_user("test#{i + 1}")
    end
  end

  def create_user(nickname)
    User.find_or_create_by(nickname: nickname) do |user|
      user.password = "password"
      user.password_confirmation = "password"
    end
  end

  def put_users
    User.all.each do |user|
      puts "User: #{user.nickname}, Role: #{user.role}"
    end
  end
end
