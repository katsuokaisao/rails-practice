# frozen_string_literal: true

module Tenants
  class TopicsController < BaseController
    before_action :set_topic, only: %i[show edit update]
    before_action -> { authorize_action!(@topic) }

    def show
      @pagination = Pagination::Paginator.new(
        relation: comments, page: params[:page], per: params[:per]
      ).call

      return unless @pagination.out_of_bounds

      flash[:alert] = t('flash.actions.out_of_bounds')
      redirect_to tenant_topic_path(tenant_slug: current_tenant.identifier, id: @topic.id)
    end

    def new
      @topic = current_tenant.topics.build
    end

    def edit; end

    def create
      @topic = current_user.topics.build(topic_params.merge(tenant: current_tenant))
      if @topic.save
        flash[:notice] = t('flash.actions.create.notice', resource: Topic.model_name.human)
        redirect_to tenant_topic_path(tenant_slug: current_tenant.identifier, id: @topic.id)
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @topic.update(topic_params)
        flash[:notice] = t('flash.actions.update.notice', resource: Topic.model_name.human)
        redirect_to tenant_topic_path(tenant_slug: current_tenant.identifier, id: @topic.id)
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_topic
      @topic = current_tenant.topics.find(params[:id])
    end

    def topic_params
      params.expect(topic: [:title])
    end

    def comments
      @topic.comments.eager_load(:author).order(created_at: :desc)
    end
  end
end
