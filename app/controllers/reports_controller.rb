# frozen_string_literal: true

class ReportsController < ApplicationController
  def new
    @topic = Topic.find(report_params[:from_topic_id])

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

    @report = Report.new(
      target_type: report_params[:reportable_type],
      reason_type: report_params[:report][:reason_type],
      reason_text: report_params[:report][:reason_text],
      reporter: current_user
    )

    case report_params[:reportable_type]
    when 'comment'
      @comment = Comment.find(report_params[:reportable_id])
      @report.target_comment = @comment
    when 'user'
      @user = User.find(report_params[:reportable_id])
      @report.target_user = @user
    end

    if @report.save
      respond_to do |format|
        format.turbo_stream { redirect_to topic_path(@topic), notice: i18n.t('flash.actions.create.notice') }
        format.html { redirect_to topic_path(@topic), notice: i18n.t('flash.actions.create.notice') }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html         { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def report_params
    params.permit(
      :reportable_type,
      :reportable_id,
      :from_topic_id,
      report: %i[reason_type reason_text]
    )
  end
end
