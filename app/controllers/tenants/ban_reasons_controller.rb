# frozen_string_literal: true

module Tenants
  class BanReasonsController < BaseController
    before_action :set_ban_reason, only: %i[edit update destroy]
    before_action -> { authorize_action!(@ban_reason) }

    def index
      @system_reasons = current_tenant.ban_reasons.system_reasons.order(created_at: :asc)
      @custom_reasons = current_tenant.ban_reasons.custom_reasons.order(created_at: :desc)
    end

    def new
      @ban_reason = current_tenant.ban_reasons.build(active: true, system: false)
    end

    def edit; end

    def create
      @ban_reason = current_tenant.ban_reasons.build(ban_reason_params)

      if @ban_reason.save
        flash[:notice] = t('flash.actions.create.notice', resource: BanReason.model_name.human)
        redirect_to tenant_ban_reasons_path(tenant_slug: current_tenant.slug)
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @ban_reason.assign_attributes(ban_reason_params)
      unless @ban_reason.editable?
        flash[:alert] = t('flash.actions.update.alert', resource: BanReason.model_name.human)
        redirect_to tenant_ban_reasons_path(tenant_slug: current_tenant.slug)
        return
      end

      if @ban_reason.save
        flash[:notice] = t('flash.actions.update.notice', resource: BanReason.model_name.human)
        redirect_to tenant_ban_reasons_path(tenant_slug: current_tenant.slug)
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @ban_reason.deletable? && @ban_reason.destroy
        flash[:notice] = t('flash.actions.destroy.notice', resource: BanReason.model_name.human)
      else
        flash[:alert] = t('flash.actions.destroy.alert', resource: BanReason.model_name.human)
      end
      redirect_to tenant_ban_reasons_path(tenant_slug: current_tenant.slug)
    end

    private

    def set_ban_reason
      @ban_reason = current_tenant.ban_reasons.find(params[:id])
    end

    def ban_reason_params
      if @ban_reason&.system?
        params.expect(ban_reason: [:active])
      else
        params.expect(ban_reason: %i[name description active])
      end
    end
  end
end
