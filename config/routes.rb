Rails.application.routes.draw do
  root to: 'home#index'

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }, skip: [:registrations]
  devise_scope :user do
    # edit を除外
    resource :registration,
             only: %i[new create update destroy],
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
    sessions: 'moderators/sessions'
  }, skip: [:registrations], path: 'moderators', path_names: { sign_in: 'sign_in', sign_out: 'sign_out' }

  get 'up' => 'rails/health#show', as: :rails_health_check
end
