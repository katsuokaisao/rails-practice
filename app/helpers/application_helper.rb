# frozen_string_literal: true

module ApplicationHelper
  def root_class_name
    [data_controller_name, data_action_name].join(' ')
  end

  def data_controller_name
    "#{controller_path.gsub('/', '_')}_controller"
  end

  def data_action_name
    "#{action_name}_action"
  end

  def display_comment_content(comment)
    if comment.hidden?
      if comment.author == current_user
        content_tag(:p, '規約違反の可能性があるため、あなたのコメントは公開画面から非表示になりました。', class: ['hidden-comment-warning'])
      else
        content_tag(:p, 'このコメントは非表示です。', class: ['hidden-comment-info'])
      end
    else
      content_tag(:div, sanitize(comment.content), class: ['comment-content'])
    end
  end

  def can_access?(controller, action, record = nil)
    policy_class_name = "#{controller.to_s.camelize}Policy"

    policy_class = policy_class_name.constantize
    policy = policy_class.new(current_user, current_moderator, record)

    policy.public_send("#{action}?")
  end
end
