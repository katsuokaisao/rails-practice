# frozen_string_literal: true

module Tenants
  class CommentsController < BaseController
    before_action :set_topic, only: %i[create]
    before_action :set_comment, only: %i[edit update]
    before_action -> { authorize_action!(@topic) }, only: [:create]
    before_action -> { authorize_action!(@comment) }, only: %i[edit update]

    def edit; end

    def create
      @comment = @topic.comments.create!(
        author: current_user,
        **comment_params
      )

      flash[:notice] = t('flash.actions.comment_created.notice')
      redirect_to tenant_topic_path(tenant_slug: current_tenant.slug, id: @topic.id)
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
      @comment.update_content!(comment_params[:content])
      flash[:notice] = t('flash.actions.update.notice', resource: Comment.model_name.human)
      redirect_to tenant_comment_histories_path(tenant_slug: current_tenant.slug, comment_id: @comment.id)
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
      @topic = current_tenant.topics.find(params[:topic_id])
    end

    def set_comment
      @comment = Comment.find(params[:id])
    end
  end
end
