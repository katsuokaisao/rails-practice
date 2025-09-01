# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    layout 'user'

    # before_action :configure_sign_up_params, only: [:create]
    before_action :configure_account_update_params, only: [:update]
    prepend_before_action :authenticate_scope!, only: %i[profile password update]

    # GET /resource/sign_up
    # def new
    #   super
    # end

    # POST /resource
    # def create
    #   super
    # end

    # GET /resource/profile
    def profile
      render :profile, layout: 'application'
    end

    # GET /resource/password
    def password
      render :password, layout: 'application'
    end

    # PUT /resource
    def update
      self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
      prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

      resource_updated = update_resource(resource, account_update_params)

      if resource_updated
        set_flash_message_for_update(resource, prev_unconfirmed_email)
        bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

        respond_with resource, location: after_update_path_for(resource)
      else
        clean_up_passwords resource
        render update_kind
      end
    end

    # DELETE /resource
    # def destroy
    #   super
    # end

    # GET /resource/cancel
    # Forces the session data which is usually expired after sign
    # in to be expired now. This is useful if the user wants to
    # cancel oauth signing in/up in the middle of the process,
    # removing all OAuth session data.
    # def cancel
    #   super
    # end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_up_params
    #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
    # end

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_account_update_params
    #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
    # end

    # The path used after sign up.
    # def after_sign_up_path_for(resource)
    #   super(resource)
    # end

    # The path used after sign up for inactive accounts.
    # def after_inactive_sign_up_path_for(resource)
    #   super(resource)
    # end

    protected

    def account_update_params
      permitted =
        case update_kind
        when :profile  then %i[nickname time_zone]
        when :password then %i[current_password password password_confirmation]
        else []
        end
      params.require(:user).permit(*permitted)
    end

    def update_resource(resource, params)
      case update_kind
      when :profile  then resource.update_without_password(params)
      when :password then resource.update_with_password(params)
      end
    end

    def configure_account_update_params
      devise_parameter_sanitizer.permit(:account_update, keys: %i[nickname time_zone])
    end

    def after_update_path_for(_resource)
      case update_kind
      when :profile  then edit_user_profile_path
      when :password then root_path
      end
    end

    def update_kind
      kind = params.dig(:user, :update_kind)
      kind.present? ? kind.to_sym : nil
    end

    def after_sign_up_path_for(_resource)
      root_path
    end
  end
end
