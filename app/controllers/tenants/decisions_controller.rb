# frozen_string_literal: true

module Tenants
  class DecisionsController < BaseController
    before_action :set_default_reportable_type, only: :index
    before_action :set_report, only: %i[new create]
    before_action :build_decision, only: %i[new create]
    before_action -> { authorize_action!(@decision) }

    def index
      @current_tab = reportable_type

      @pagination = Pagination::Paginator.new(
        relation: decisions, page: params[:page], per: params[:per]
      ).call

      return unless @pagination.out_of_bounds

      flash[:alert] = t('flash.actions.out_of_bounds')
      redirect_to tenant_decisions_path(tenant_slug: current_tenant.slug)
    end

    def new
      @user_time_zone_identifier = user_time_zone_identifier
      respond_to(&:turbo_stream)
    end

    def create
      @decision.assign_attributes(decision_params)

      begin
        @decision.save!
        redirect_to_reports_page
      rescue ActiveRecord::RecordNotUnique
        handle_concurrent_modification
      rescue ActiveRecord::RecordInvalid => e
        handle_invalid_record(e)
      end
    end

    private

    def set_default_reportable_type
      params[:reportable_type] ||= 'comment'
    end

    def set_report
      @report = current_tenant.reports.find(params[:report_id] || params[:decision][:report_id])
    end

    def build_decision
      @decision = current_tenant.decisions.build(report: @report, decider: current_moderator)
    end

    def decision_params
      params.expect(decision: %i[decision_type note suspended_until])
    end

    def reportable_type
      params[:reportable_type].presence_in(%w[comment user]) ||
        raise(ActionController::BadRequest, "invalid reportable_type: #{params[:reportable_type]}")
    end

    def decisions
      current_tenant.decisions
                    .includes(includes_list_for_decisions)
                    .joins(:report)
                    .where(reports: { reportable_type: reportable_type })
                    .order(created_at: :desc)
    end

    def includes_list_for_decisions
      case reportable_type
      when 'comment'
        comment_decision_includes
      when 'user'
        user_decision_includes
      end
    end

    def comment_decision_includes
      [
        :decider,
        {
          report: [
            { reporter: :tenant_memberships },
            { reportable: [:topic, { author: :tenant_memberships }] },
            :ban_reason
          ]
        }
      ]
    end

    def user_decision_includes
      [
        :decider,
        {
          report: [
            { reporter: :tenant_memberships },
            { reportable: :tenant_memberships },
            :ban_reason
          ]
        }
      ]
    end

    def redirect_to_reports_page
      flash[:notice] = t('flash.actions.create.notice', resource: Decision.model_name.human)
      redirect_to tenant_reports_path(tenant_slug: current_tenant.slug,
                                      reportable_type: @report.reportable_type.downcase)
    end

    def handle_concurrent_modification
      flash[:alert] = t('flash.actions.create.alert', resource: Decision.model_name.human)
      flash[:alert] << t('flash.actions.conflict')
      redirect_to tenant_reports_path(tenant_slug: current_tenant.slug,
                                      reportable_type: @report.reportable_type.downcase)
    end

    def handle_invalid_record(exception)
      @decision = exception.record
      respond_to do |format|
        format.turbo_stream { render :create_error, status: :unprocessable_content }
      end
    end
  end
end
