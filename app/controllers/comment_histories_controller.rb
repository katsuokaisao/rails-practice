# frozen_string_literal: true

class CommentHistoriesController < ApplicationController
  before_action :set_comment
  before_action :set_versions

  def index
    @pagination = Pagination::Paginator.new(
      relation: @comment.histories.order(version_no: :desc), page: params[:page], per: 5
    ).call
    redirect_to topics_path, alert: t('flash.actions.out_of_bounds') if @pagination.out_of_bounds
  end

  def compare
    @from = params[:from].to_i
    @to = params[:to].to_i
    @compare_from_history = @comment.histories.eager_load(:author).find_by(version_no: @from)
    @compare_to_history = @comment.histories.eager_load(:author).find_by(version_no: @to)
  end

  private

  def set_comment
    @comment = Comment.find(params[:comment_id])
  end

  def set_versions
    @versions = @comment.histories.pluck(:version_no).sort.reverse
  end
end
