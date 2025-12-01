# frozen_string_literal: true

module Tenants
  class ReportsController < BaseController
    REPORTABLE_TYPE_MAP = Report::REPORTABLE_CLASSES.index_by { |k| k.name.downcase }.freeze

    before_action :set_default_reportable_type, only: :index
    before_action :set_topic, only: %i[new create]
    before_action :set_report, only: %i[new create]
    before_action -> { authorize_action!(@report) }

    def index
      @current_tab = reportable_type

      @pagination = Pagination::Paginator.new(
        relation: reports, page: params[:page], per: params[:per]
      ).call

      return unless @pagination.out_of_bounds

      flash[:alert] = t('flash.actions.out_of_bounds')
      redirect_to tenant_reports_path(tenant_slug: current_tenant.slug)
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
      @report.assign_attributes(create_params)

      respond_to do |format|
        format.turbo_stream do
          if @report.save
            flash[:notice] = t('flash.actions.create.notice', resource: Report.model_name.human)
            redirect_to tenant_topic_path(tenant_slug: @topic.tenant.slug, id: @topic)
          else
            render :create_error, status: :unprocessable_content
          end
        end
      end
    end

    private

    def reports
      reports = current_tenant.reports.where(reportable_type: reportable_type)
                              .where.missing(:decision)
                              .includes(:reporter, :reportable, :ban_reason)
                              .order(created_at: :desc)

      case reportable_type
      when 'comment'
        reports = reports.includes(reportable: %i[topic author])
      end

      reports
    end

    def reportable_type
      params[:reportable_type].presence_in(REPORTABLE_TYPE_MAP) ||
        raise(ActionController::BadRequest, "invalid reportable_type: #{params[:reportable_type]}")
    end

    def set_default_reportable_type
      params[:reportable_type] ||= 'comment'
    end

    def set_topic
      @topic = current_tenant.topics.find(params[:from_topic_id])
    end

    def set_report
      klass = REPORTABLE_TYPE_MAP[reportable_type]
      @report = current_user.authored_reports.build(
        reportable: klass.find(params[:reportable_id])
      )
      @report.tenant = current_tenant
    end

    def create_params
      params.expect(report: %i[ban_reason_id reason_text])
    end
  end
end
