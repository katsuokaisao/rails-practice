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

    get 'moderators/sign_in', to: 'moderators/sessions#new', as: :new_moderator_session
    post 'moderators/sign_in', to: 'moderators/sessions#create', as: :moderator_session
    delete 'moderators/sign_out', to: 'moderators/sessions#destroy', as: :destroy_moderator_session
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
end
