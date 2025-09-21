# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_topic, only: %i[create edit update]
  before_action :set_comment, only: %i[edit update]
  before_action -> { authorize_action!(@comment) }

  def edit; end

  def create
    @comment = Comment.create!(
      topic: @topic,
      author: current_user,
      **comment_params
    )

    redirect_to @topic, notice: t('flash.actions.comment_created.notice')
  rescue ActiveRecord::RecordInvalid => e
    @comment = e.record
    set_pagination

    respond_to do |format|
      format.turbo_stream do
        render :create_error, status: :unprocessable_content
      end
    end
  end

  def update
    @comment.update!(comment_params)
    redirect_to comment_histories_path(@comment),
                notice: t('flash.actions.update.notice', resource: Comment.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    @comment = e.record
    render :edit, status: :unprocessable_content
  end

  private

  def comment_params
    params.expect(comment: [:content])
  end

  def set_pagination
    @pagination = Pagination::Paginator.new(
      relation: @topic.comments, page: params[:page], per: params[:per]
    ).call
  end

  def set_topic
    @topic = Topic.find(params[:topic_id])
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end
end
