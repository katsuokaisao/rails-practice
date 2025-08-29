# frozen_string_literal: true

class DecisionsController < ApplicationController
  def new
    @report = Report.find(params[:report_id])
    @decision = Decision.new(report: @report)

    authorize_action!(@decision)

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

    authorize_action!(@decision)

    begin
      ActiveRecord::Base.transaction do
        @decision.save!

        case @decision.decision_type
        when 'hide_comment'
          @report.target_comment.hide(cause: :comment_invisible, decision: @decision)
        when 'suspend_user'
          @report.target_user.suspend!(@decision.suspension_until)

          @report.target_user.comments.update_all(
            hidden: true,
            hidden_cause: :user_suspended,
            hidden_cause_decision: @decision
          )
        end
      end

      case @decision.decision_type
      when 'hide_comment'
        similar_reports = Report.where(
          target_comment_id: @report.target_comment_id,
          target_type: 'comment'
        ).where.not(id: @report.id)

        similar_reports.each do |similar_report|
          next if similar_report.reviewed?

          Decision.create!(
            report: similar_report,
            decision_type: 'hide_comment',
            note: "自動作成: 関連する通報 ##{@report.id} の審査結果に基づく",
            moderator: current_moderator
          )
        end
      when 'suspend_user'
        similar_reports = Report.where(
          target_user_id: @report.target_user_id,
          target_type: 'user'
        ).where.not(id: @report.id)

        similar_reports.each do |similar_report|
          next if similar_report.reviewed?

          Decision.create!(
            report: similar_report,
            decision_type: 'suspend_user',
            note: "自動作成: 関連する通報 ##{@report.id} の審査結果に基づく",
            suspension_until: @decision.suspension_until,
            moderator: current_moderator
          )
        end
      end

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
