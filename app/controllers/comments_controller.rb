# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_comment, only: %i[edit update]
  before_action -> { authorize_action!(@comment) }

  def edit
    @topic = @comment.topic
  end

  def create
    @topic = Topic.find(params[:topic_id])

    begin
      @comment = Comment.create_with_history!(
        topic: @topic,
        author: current_user,
        content: comment_params[:content]
      )

      redirect_to @topic, notice: t('flash.actions.comment_created.notice')
    rescue ActiveRecord::RecordInvalid => e
      @comment = e.record
      set_pagination

      respond_to do |format|
        format.html do
          render topic_path(@topic), status: :unprocessable_entity
        end
        format.turbo_stream do
          render :create_error, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    @comment.update_content!(comment_params[:content])
    redirect_to @comment.topic, notice: t('flash.actions.update.notice', resource: Topic.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    @comment = e.record
    render :edit, status: :unprocessable_entity
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end

  def set_pagination
    @pagination = Pagination::Paginator.new(
      relation: @topic.comments, page: params[:page], per: params[:per]
    ).call
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end
end
