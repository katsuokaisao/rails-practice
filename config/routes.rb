# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  # Sidekiq Web UI（Basic認証付き）
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(username),
      Digest::SHA256.hexdigest(ENV.fetch('SIDEKIQ_USERNAME', 'admin'))
    ) &
      ActiveSupport::SecurityUtils.secure_compare(
        Digest::SHA256.hexdigest(password),
        Digest::SHA256.hexdigest(ENV.fetch('SIDEKIQ_PASSWORD', 'password'))
      )
  end
  mount Sidekiq::Web => '/sidekiq'

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }, skip: [:registrations]
  devise_scope :user do
    # edit, destroy を除外
    resource :registration,
             only: %i[new create update],
             controller: 'users/registrations',
             path: 'users',
             as: :user_registration,
             path_names: { new: 'sign_up' } do
      get :cancel, on: :collection
    end
    get 'users/profile',  to: 'users/registrations#profile',  as: :edit_user_profile
    get 'users/password', to: 'users/registrations#password', as: :edit_user_password
  end

  devise_for :moderators, controllers: {
    sessions: 'moderators/sessions',
    registrations: 'moderators/registrations'
  }, skip: [:registrations], path: 'moderators', path_names: { sign_in: 'sign_in', sign_out: 'sign_out' }
  devise_scope :moderator do
    resource :registration,
             only: %i[update],
             controller: 'moderators/registrations',
             path: 'moderators',
             as: :moderator_registration
    get 'moderators/profile',  to: 'moderators/registrations#profile',  as: :edit_moderator_profile
    get 'moderators/password', to: 'moderators/registrations#password', as: :edit_moderator_password
  end

  namespace :my do
    resources :invitations, only: %i[index] do
      member do
        get :accept
        post :accept, action: :create_acceptance
        post :reject
      end
    end
  end

  resource :unsubscription, only: %i[new create]

  namespace :admin do
    resources :tenants, only: %i[edit update]
    # TODO: reports, decisionsもこっちに移行する
  end

  get 'up' => 'rails/health#show', as: :rails_health_check

  root to: 'tenants#index'
  scope '/:tenant_slug', as: :tenant do
    get '/', to: 'tenants#show', as: ''

    scope module: 'tenants' do
      resources :invitations, only: %i[new create]
      resource :membership, only: %i[edit update]

      resources :topics, except: %i[index destroy] do
        resources :comments, only: %i[create edit update], shallow: true
      end

      resources :comments, only: %i[] do
        resources :histories, controller: 'comment_histories', only: %i[index] do
          get 'compare', on: :collection
        end
      end

      resources :reports, only: %i[index new create]
      resources :decisions, only: %i[index new create]
      resources :ban_reasons, except: %i[show]
    end
  end
end
