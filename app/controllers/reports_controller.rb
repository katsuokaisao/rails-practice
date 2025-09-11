# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :set_topic, only: %i[new create]
  before_action :set_report, only: %i[new create]
  before_action -> { authorize_action!(@report) }

  def index
    params[:target_type] ||= 'comment'
    @current_tab = params[:target_type]

    @pagination = Pagination::Paginator.new(
      relation: reports, page: params[:page], per: params[:per]
    ).call

    redirect_to reports_path, alert: t('flash.actions.out_of_bounds') if @pagination.out_of_bounds
  end

  def new
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          'modal-root',
          partial: 'modal',
          locals: { topic: @topic, report: @report }
        )
      end
    end
  end

  def create
    @report.assign_attributes(
      reason_type: report_params[:report][:reason_type],
      reason_text: report_params[:report][:reason_text]
    )

    if @report.save
      respond_to do |format|
        format.turbo_stream do
          redirect_to topic_path(@topic), notice: t('flash.actions.create.notice', resource: Report.model_name.human)
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render :create_error, status: :unprocessable_content
        end
      end
    end
  end

  private

  def reports
    reports = Report.where(target_type: params[:target_type])
                  .where.missing(:decision)
                  .order(created_at: :desc)

    case params[:target_type]
    when 'comment'
      reports = reports.includes(:reporter, target: %i[topic author])
    when 'user'
      reports = reports.includes(:reporter, :target)
    end

    reports
  end

  def set_topic
    @topic = Topic.find(report_params[:from_topic_id])
  end

  def set_report
    @report = current_user.reports.build(
      target_type: report_params[:reportable_type]
    )
    case report_params[:reportable_type].downcase
    when 'comment'
      @comment = Comment.find(report_params[:reportable_id])
      @report.target = @comment
    when 'user'
      @user = User.find(report_params[:reportable_id])
      @report.target = @user
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
