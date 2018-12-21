Rails.application.routes.draw do
  get 'sessions/new'
  post 'sessions/create'
  get 'sessions/destroy'

  get 'home', to: 'static#home'
  get 'contact', to: 'static#contact'
  get 'privacy', to: 'static#privacy'

  resources :people, param: :random_id
  get 'verify_email/:verification_token', to: 'people#verify_email'
  get 'change_password', to: 'people#change_password'
  get 'change_state/:random_id/:state', to: 'people#change_state'

  resources :groups
  get 'done/:id', to: 'groups#done'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'static#home'
end
