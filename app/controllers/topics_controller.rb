# frozen_string_literal: true

class TopicsController < ApplicationController
  before_action :authenticate_user!, only: %i[create update]
  before_action :set_topic, only: %i[show edit update]

  def index
    @topics = Topic.eager_load(:author).order(created_at: :desc)
  end

  def show; end

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
end
