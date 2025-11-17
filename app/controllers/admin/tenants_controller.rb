# frozen_string_literal: true

module Admin
  class TenantsController < BaseController
    before_action -> { authorize_action! }

    def edit; end

    def update
      if current_tenant.update(tenant_params)
        redirect_to tenant_path(tenant_slug: current_tenant.identifier), notice: t('.success')
      else
        render :edit, status: :unprocessable_entity, alert: t('.failure')
      end
    end

    private

    def tenant_params
      params.expect(
        tenant: %i[unsubscribed_user_topic_policy
                   unsubscribed_user_comment_policy]
      )
    end
  end
end
