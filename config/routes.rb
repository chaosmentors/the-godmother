Rails.application.routes.draw do
  resources :password_resets, only: [:edit, :update]

  get "password_resets/edit"
  get 'sessions/new'
  post 'sessions/create'
  get 'sessions/destroy'

  resources :people, param: :random_id
  get 'change_password', to: 'people#change_password'
  get 'change_state/:random_id/:state', to: 'people#change_state'
  get 'search', to: 'people#search'

  resources :groups
  get 'done/:id', to: 'groups#done'
  get :batch_create_groups, to: 'groups#batch_create_groups'

  resources :people do
    member do
      post :send_password_reset
    end
  end

  scope "(:locale)", locale: /en|de/ do
    get 'contact', to: 'static#contact'
    get 'verify_email/:verification_token', to: 'people#verify_email'
    get 'people/new', to: 'people#new'

    root to: 'static#home'
  end
end
