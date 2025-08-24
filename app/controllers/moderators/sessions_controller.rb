# frozen_string_literal: true

module Moderators
  # モデレーターセッションコントローラー
  #
  # モデレーターのログイン・ログアウト処理を制御する。
  # Deviseの標準機能を使用してモデレーター認証セッションを管理する。
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

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end
  end
end
