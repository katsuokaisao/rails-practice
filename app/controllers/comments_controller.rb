# frozen_string_literal: true

class CommentsController < ApplicationController
  def create
    @topic = Topic.find(params[:topic_id])

    @comment = @topic.comments.new(comment_params.merge(author: current_user, current_version_no: 1))
    unless @comment.valid?
      set_pagination

      respond_to do |format|
        format.html do
          render topic_path(@topic), status: :unprocessable_entity
        end
        format.turbo_stream do
          render :create_error, status: :unprocessable_entity
        end
      end
      return
    end

    Comment.transaction do
      @comment.save!
      @comment.histories.create!(
        topic: @topic,
        author: current_user,
        version_no: 1,
        content: @comment.content
      )
    end

    respond_to do |format|
      format.html do
        redirect_to @topic, notice: t('flash.actions.comment_created.notice')
      end
      format.turbo_stream
    end
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
end
