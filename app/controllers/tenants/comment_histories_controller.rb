# frozen_string_literal: true

module Tenants
  class CommentHistoriesController < BaseController
    before_action :set_comment
    before_action :set_versions
    before_action -> { authorize_action!(@comment) }

    def index
      @pagination = Pagination::Paginator.new(
        relation: histories, page: params[:page], per: params[:per] || 5
      ).call

      return unless @pagination.out_of_bounds

      flash[:alert] = t('flash.actions.out_of_bounds')
      redirect_to tenant_topics_path(tenant_slug: current_tenant.identifier)
    end

    def compare
      @from = params[:from].to_i
      @to = params[:to].to_i

      if @from == @to
        flash[:alert] = t('.same_version_error')
        redirect_to tenant_comment_histories_path(tenant_slug: current_tenant.identifier, comment_id: @comment.id)
        return
      end

      histories = @comment.histories.eager_load(:author).where(version_no: [@from, @to]).index_by(&:version_no)

      if histories.size < 2
        flash[:alert] = t('flash.actions.out_of_bounds')
        redirect_to tenant_comment_histories_path(tenant_slug: current_tenant.identifier, comment_id: @comment.id)
        return
      end

      @compare_from_history = histories[@from]
      @compare_to_history = histories[@to]
    end

    private

    def set_comment
      @comment = current_tenant.comments.find(params[:comment_id])
    end

    def histories
      @comment.histories.eager_load(:author).order(version_no: :desc)
    end

    def set_versions
      @versions = @comment.histories.pluck(:version_no).sort.reverse
    end
  end
end
