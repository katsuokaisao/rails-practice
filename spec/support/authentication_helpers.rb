# frozen_string_literal: true

module AuthenticationHelpers
  def sign_in_user(nickname: 'testuser', password: 'password123')
    user = User.find_or_create_by!(nickname: nickname) do |u|
      u.password = password
      u.password_confirmation = password
    end
    sign_in user
  end

  def sign_in_moderator(nickname: 'testmoderator', password: 'password123')
    moderator = Moderator.find_or_create_by!(nickname: nickname) do |u|
      u.password = password
      u.password_confirmation = password
    end
    sign_in moderator
  end

  def sign_out_user
    sign_out :user
  end

  def sign_out_moderator
    sign_out :moderator
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :system
end
