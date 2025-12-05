# frozen_string_literal: true

module Admin
  class TenantsController < BaseController
    before_action -> { authorize_action! }

    def edit; end

    def update
      if current_tenant.update(tenant_params)
        redirect_to edit_admin_tenant_path(current_tenant), notice: t('.success')
      else
        render :edit, status: :unprocessable_entity
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
