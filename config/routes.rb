Rails.application.routes.draw do
  root to: 'home#index'

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  devise_scope :user do
    get 'moderators/sign_in', to: 'moderators/sessions#new', as: :new_moderator_session
    post 'moderators/sign_in', to: 'moderators/sessions#create', as: :moderator_session
    delete 'moderators/sign_out', to: 'moderators/sessions#destroy', as: :destroy_moderator_session
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
end
