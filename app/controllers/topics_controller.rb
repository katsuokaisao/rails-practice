# frozen_string_literal: true

class TopicsController < ApplicationController
  before_action :authenticate_user!, only: %i[create update]
  before_action :set_topic, only: %i[show edit update]
  before_action -> { authorize_action!(@topic) }

  def index
    @pagination = Pagination::Paginator.new(
      relation: topics, page: params[:page], per: params[:per]
    ).call

    redirect_to topics_path, alert: t('flash.actions.out_of_bounds') if @pagination.out_of_bounds
  end

  def show
    @pagination = Pagination::Paginator.new(
      relation: comments, page: params[:page], per: params[:per]
    ).call

    redirect_to topic_path(@topic), alert: t('flash.actions.out_of_bounds') if @pagination.out_of_bounds
  end

  def new
    @topic = Topic.new
  end

  def edit; end

  def create
    @topic = current_user.topics.build(topic_params)
    if @topic.save
      redirect_to @topic, notice: t('flash.actions.create.notice', resource: Topic.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @topic.update(topic_params)
      redirect_to @topic, notice: t('flash.actions.update.notice', resource: Topic.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_topic
    @topic = Topic.find(params[:id])
  end

  def topic_params
    params.require(:topic).permit(:title)
  end

  def topics
    Topic
      .order(created_at: :desc, id: :desc)
      .includes(:author)
  end

  def comments
    @topic.comments.eager_load(:author).order(created_at: :desc)
  end
end
