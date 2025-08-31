# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :set_report, only: %i[new create]
  before_action -> { authorize_action!(@report) }

  def index
    params[:target_type] ||= 'comment'

    @pagination = Pagination::Paginator.new(
      relation: reports, page: params[:page], per: params[:per]
    ).call

    @current_tab = params[:target_type]

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @topic = Topic.find(report_params[:from_topic_id])

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          'modal-root',
          partial: 'reports/modal',
          locals: { topic: @topic, report: @report }
        )
      end
      format.html
    end
  end

  def create
    @topic = Topic.find(report_params[:from_topic_id])

    @report.assign_attributes(
      target_type: report_params[:reportable_type],
      reason_type: report_params[:report][:reason_type],
      reason_text: report_params[:report][:reason_text],
      reporter: current_user
    )

    if @report.save
      respond_to do |format|
        format.turbo_stream do
          redirect_to topic_path(@topic), notice: t('flash.actions.create.notice', resource: Report.model_name.human)
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def reports
    reports = case params[:target_type]
              when 'comment'
                Report.eager_load(:reporter, :target_comment, :target_user)
                      .eager_load(target_comment: %i[topic author])
              when 'user'
                Report.eager_load(:reporter, :target_user)
              end
    reports = reports.where.missing(:decision)
    reports = reports.where(target_type: params[:target_type]) if %w[comment user].include?(params[:target_type])
    reports.order('reports.created_at DESC')
  end

  def set_report
    @report = Report.new(
      target_type: report_params[:reportable_type]
    )
    case report_params[:reportable_type]
    when 'comment'
      @comment = Comment.find(report_params[:reportable_id])
      @report.target_comment = @comment
    when 'user'
      @user = User.find(report_params[:reportable_id])
      @report.target_user = @user
    end
  end

  def report_params
    params.permit(
      :reportable_type,
      :reportable_id,
      :from_topic_id,
      report: %i[reason_type reason_text]
    )
  end
end
