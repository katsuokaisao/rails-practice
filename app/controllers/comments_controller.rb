# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment, only: %i[edit update]
  def edit
    @topic = @comment.topic
  end

  def create
    @topic = Topic.find(params[:topic_id])

    @comment = @topic.comments.new(comment_params.merge(author: current_user, current_version_no: 1))
    if @comment.save
      respond_to do |format|
        format.html do
          redirect_to @topic, notice: t('flash.actions.comment_created.notice')
        end
        format.turbo_stream
      end
    else
      set_pagination

      respond_to do |format|
        format.html do
          render topic_path(@topic), status: :unprocessable_entity
        end
        format.turbo_stream do
          render :create_error, status: :unprocessable_entity
        end
      end
      nil
    end
  end

  def update
    @topic = @comment.topic
    @comment.assign_attributes(comment_params)
    @comment.current_version_no += 1

    unless @comment.save
      render :edit, status: :unprocessable_entity
      return
    end

    redirect_to @topic, notice: t('flash.actions.update.notice', resource: Topic.model_name.human)
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
