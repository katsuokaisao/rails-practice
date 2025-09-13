# frozen_string_literal: true

class CommentHistoriesController < ApplicationController
  before_action :set_comment
  before_action :set_versions
  before_action -> { authorize_action!(@comment) }

  def index
    @pagination = Pagination::Paginator.new(
      relation: histories, page: params[:page], per: params[:per] || 5
    ).call
    redirect_to topics_path, alert: t('flash.actions.out_of_bounds') if @pagination.out_of_bounds
  end

  def compare
    @from = params[:from].to_i
    @to = params[:to].to_i

    if @from == @to
      redirect_to comment_histories_path(@comment), alert: t('.same_version_error')
      return
    end

    histories = @comment.histories.eager_load(:author).where(version_no: [@from, @to]).index_by(&:version_no)

    redirect_to comment_histories_path(@comment), alert: t('flash.actions.out_of_bounds') if histories.size < 2

    @compare_from_history = histories[@from]
    @compare_to_history = histories[@to]
  end

  private

  def set_comment
    @comment = Comment.find(params[:comment_id])
  end

  def histories
    @comment.histories.eager_load(:author).order(version_no: :desc)
  end

  def set_versions
    @versions = @comment.histories.pluck(:version_no).sort.reverse
  end
end
