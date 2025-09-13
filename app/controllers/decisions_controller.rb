# frozen_string_literal: true

class DecisionsController < ApplicationController
  before_action :set_report, only: %i[new create]
  before_action :build_decision, only: %i[new create]
  before_action -> { authorize_action!(@decision) }

  def index
    @current_tab = target_type

    @pagination = Pagination::Paginator.new(
      relation: decisions, page: params[:page], per: params[:per]
    ).call

    redirect_to decisions_path, alert: t('flash.actions.out_of_bounds') if @pagination.out_of_bounds
  end

  def new
    @user_time_zone_identifier = user_time_zone_identifier
    respond_to do |format|
      format.turbo_stream
    end
  end

  def create
    @decision.assign_attributes(decision_params.slice(:decision_type, :note, :suspension_until))

    begin
      @decision.execute!
      redirect_to_reports_page
    rescue ActiveRecord::RecordNotUnique
      handle_concurrent_modification
    rescue ActiveRecord::RecordInvalid => e
      handle_invalid_record(e)
    end
  end

  private

  def set_report
    @report = Report.find(params[:report_id] || decision_params[:report_id])
  end

  def build_decision
    @decision = current_moderator.decisions.build(report: @report)
  end

  def decision_params
    params.expect(decision: %i[report_id decision_type note suspension_until])
  end

  def target_type
    params[:target_type] ||= 'comment'
    params[:target_type].presence_in(%w[comment user]) ||
      raise(ActionController::BadRequest, "invalid target_type: #{params[:target_type]}")
  end

  def decisions
    decisions = case target_type
                when 'comment'
                  Decision.includes(:decider, report: [:reporter, { target: %i[topic author] }])
                          .joins(:report).where(reports: { target_type: target_type })
                when 'user'
                  Decision.includes(:decider, { report: %i[reporter target] })
                          .joins(:report).where(reports: { target_type: target_type })
                end
    decisions.order(created_at: :desc)
  end

  def redirect_to_reports_page
    flash[:notice] = t('flash.actions.create.notice', resource: Decision.model_name.human)
    redirect_to reports_path(target_type: @report.target_type.downcase)
  end

  def handle_concurrent_modification
    flash[:alert] = t('flash.actions.create.alert', resource: Decision.model_name.human)
    flash[:alert] << t('flash.actions.conflict')
    redirect_to reports_path(target_type: @report.target_type.downcase)
  end

  def handle_invalid_record(exception)
    @decision = exception.record

    respond_to do |format|
      format.turbo_stream do
        render :create_error, status: :unprocessable_content
      end
    end
  end
end
