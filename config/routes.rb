Rails.application.routes.draw do
  resources :password_resets, only: [:edit, :update]

  get "password_resets/edit"
  get 'sessions/new'
  post 'sessions/create'
  get 'sessions/destroy'

  get 'home', to: 'static#home'
  get 'contact', to: 'static#contact'
  get 'privacy', to: 'static#privacy'
  get 'imprint', to: 'static#imprint'
  get 'cookies', to: 'static#cookies'

  resources :people, param: :random_id
  get 'verify_email/:verification_token', to: 'people#verify_email'
  get 'change_password', to: 'people#change_password'
  get 'change_state/:random_id/:state', to: 'people#change_state'

  resources :groups
  get 'done/:id', to: 'groups#done'
  get 'static/setCookie', to: 'static#setCookie'

  resources :people do
    member do
      post :send_password_reset
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'static#home'
end
