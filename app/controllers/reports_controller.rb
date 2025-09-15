# frozen_string_literal: true

class ReportsController < ApplicationController
  REPORTABLE_TYPE_MAP = Report::REPORTABLE_CLASSES.index_by { |k| k.name.downcase }.freeze

  before_action :set_topic, only: %i[new create]
  before_action :set_report, only: %i[new create]
  before_action -> { authorize_action!(@report) }

  def index
    @current_tab = reportable_type

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
    reports = Report.where(reportable_type: reportable_type)
                  .where.missing(:decision)
                  .includes(:reporter, :reportable)
                  .order(created_at: :desc)

    case reportable_type
    when 'comment'
      reports = reports.includes(reportable: %i[topic author])
    end

    reports
  end

  def reportable_type
    params[:reportable_type] ||= 'comment'
    params[:reportable_type].presence_in(REPORTABLE_TYPE_MAP) ||
      raise(ActionController::BadRequest, "invalid reportable_type: #{params[:reportable_type]}")
  end

  def set_topic
    @topic = Topic.find(report_params[:from_topic_id])
  end

  def set_report
    klass = REPORTABLE_TYPE_MAP[reportable_type]
    @report = current_user.reports.build(
      reportable: klass.find(report_params[:reportable_id])
    )
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
