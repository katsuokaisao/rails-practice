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

  def render_comment_content(comment)
    return render_unsubscribed_comment_content(comment) if comment_author_unsubscribed?(comment)
    return render_visible_comment_content(comment) unless comment.invisible?
    return content_tag(:p, 'このコメントは非表示です。', class: ['hidden-comment-info']) if comment.author != current_user

    render_invisible_comment_warning(comment)
  end

  private

  def render_unsubscribed_comment_content(comment)
    tenant = comment.topic.tenant
    content = tenant.comment_hide_content? ? I18n.t('helpers.application.hidden_comment_content') : comment.content
    content_tag(:div, simple_format(sanitize(content)), class: ['comment-content'])
  end

  def render_visible_comment_content(comment)
    content_tag(:div, simple_format(sanitize(comment.content)), class: ['comment-content'])
  end

  def render_invisible_comment_warning(comment)
    tenant = comment.topic.tenant
    message = if comment.author.suspended?(tenant)
                "規約違反の可能性があるため、アカウントが停止されています。停止期間は#{comment.author.suspended_until_date(tenant)}です。"
              else
                '規約違反の可能性があるため、あなたのコメントは非表示になりました。'
              end
    content_tag(:p, message, class: ['hidden-comment-warning'])
  end

  def comment_author_unsubscribed?(comment)
    author = comment.author
    membership = if author.association(:tenant_memberships).loaded?
                   author.tenant_memberships.detect { |tm| tm.tenant_id == comment.topic.tenant_id }
                 else
                   author.tenant_memberships.find_by(tenant_id: comment.topic.tenant_id)
                 end
    membership&.unsubscribed?
  end

  def can_access?(controller, action, record = nil)
    policy_class_name = "#{controller.to_s.camelize}Policy"

    policy_class = policy_class_name.constantize
    policy = policy_class.new(current_user, current_moderator, current_tenant, record)

    policy.public_send("#{action}?")
  end

  def only_user_signed_in?
    user_signed_in? && !moderator_signed_in?
  end

  def pending_invitations_count
    return 0 unless user_signed_in?

    current_user.pending_invitations_count
  end

  def display_name(user)
    user.decorate.display_name_for(current_tenant)
  end

  def display_name_with_id(user)
    name = display_name(user)

    content_tag(:span, class: 'user-info') do
      concat(content_tag(:span, name, class: 'user-name'))
      concat(' ')
      concat(content_tag(:span, "(ID: #{user.id})", class: 'user-id'))
    end
  end
end
