# frozen_string_literal: true

class DecisionsController < ApplicationController
  before_action -> { authorize_action!(@decision) }

  def index
    params[:target_type] ||= 'comment'

    decisions = case params[:target_type]
                when 'comment'
                  Decision.eager_load(:report, :moderator)
                          .eager_load(report: %i[reporter target_comment])
                          .eager_load(report: { target_comment: %i[topic author] })
                          .where(reports: { target_type: 'comment' })
                when 'user'
                  Decision.eager_load(:report, :moderator)
                          .eager_load(report: %i[reporter target_user])
                          .where(reports: { target_type: 'user' })
                end
    decisions = decisions.order(created_at: :desc)

    @pagination = Pagination::Paginator.new(
      relation: decisions, page: params[:page], per: params[:per]
    ).call

    @current_tab = params[:target_type]

    redirect_to topics_path, alert: t('flash.actions.out_of_bounds') if @pagination.out_of_bounds

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @report = Report.find(params[:report_id])
    @decision = Decision.new(report: @report)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def create
    @report = Report.find(decision_params[:report_id])
    @decision = Decision.new(
      report: @report,
      decision_type: decision_params[:decision_type],
      note: decision_params[:note],
      suspension_until: decision_params[:suspension_until],
      moderator: current_moderator
    )

    begin
      @decision.execute!
      redirect_to_reports_page
    rescue ActiveRecord::RecordNotUnique
      handle_concurrent_modification
    rescue ActiveRecord::RecordInvalid => e
      @decision = e.record
      handle_invalid_record(e)
    end
  end

  private

  def decision_params
    params.require(:decision).permit(:report_id, :decision_type, :note, :suspension_until)
  end

  def redirect_to_reports_page
    respond_to do |format|
      format.turbo_stream do
        redirect_to reports_path(target_type: @report.target_type)
      end
    end
  end

  def handle_concurrent_modification
    respond_to do |format|
      format.turbo_stream do
        render json: { error: 'concurrent_modification' }, status: :conflict
      end
    end
  end

  def handle_invalid_record(exception)
    @decision = exception.record

    respond_to do |format|
      format.turbo_stream do
        render :new, status: :unprocessable_entity
      end
    end
  end
end
