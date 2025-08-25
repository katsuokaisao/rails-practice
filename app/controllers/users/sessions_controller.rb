# frozen_string_literal: true

module Users
  # ユーザーセッションコントローラー
  #
  # ユーザーのログイン・ログアウト処理を制御する。
  # Deviseの標準機能を使用してユーザー認証セッションを管理する。
  class SessionsController < Devise::SessionsController
    # before_action :configure_sign_in_params, only: [:create]
    layout 'user'

    # GET /resource/sign_in
    # def new
    #   super
    # end

    # POST /resource/sign_in
    # def create
    #   super
    # end

    # DELETE /resource/sign_out
    # def destroy
    #   super
    # end

    protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end

    def after_sign_in_path_for(_resource)
      root_path
    end

    def after_sign_out_path_for(_resource)
      new_user_session_path
    end
  end
end
