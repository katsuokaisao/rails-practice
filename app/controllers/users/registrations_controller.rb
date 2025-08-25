# frozen_string_literal: true

module Users
  # ユーザー登録コントローラー
  #
  # ユーザーの新規登録、プロフィール更新、パスワード変更を制御する。
  # Deviseの標準機能を拡張してカスタムレイアウトと更新処理を提供する。
  class RegistrationsController < Devise::RegistrationsController
    layout 'user'

    # before_action :configure_sign_up_params, only: [:create]
    # before_action :configure_account_update_params, only: [:update]
    prepend_before_action :authenticate_scope!, only: %i[profile password update destroy]

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
      render :profile
    end

    # GET /resource/password
    def password
      render :password
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

    def update_resource(resource, params)
      case update_kind
      when :profile  then resource.update_without_password(params)
      when :password then resource.update_with_password(params)
      end
    end

    def after_update_path_for(_resource)
      case update_kind
      when :profile  then edit_user_profile_path
      when :password then root_path
      end
    end

    def update_kind
      update_kind_params = params.require(:user).permit(:update_kind)
      update_kind_params[:update_kind].to_sym if update_kind_params[:update_kind].present?
    end
  end
end
