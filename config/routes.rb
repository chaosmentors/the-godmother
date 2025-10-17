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

  get 'settings', to: 'settings#index'
  post 'settings', to: 'settings#update'
  post 'settings/send_ticket_reminders', to: 'settings#send_ticket_reminders'
  get 'settings/export_csv', to: 'settings#export_csv', as: :settings_export_csv
  get 'settings/export_matchable_csv', to: 'settings#export_matchable_csv', as: :settings_export_matchable_csv

  get 'conference_ticket/:verification_token/edit', to: 'conference_tickets#edit', as: :edit_conference_ticket
  patch 'conference_ticket/:verification_token', to: 'conference_tickets#update', as: :conference_ticket

  resources :groups
  get 'done/:id', to: 'groups#done'
  get :batch_create_groups, to: 'groups#batch_create_groups'
  get :csv_batch_create_groups, to: 'groups#csv_batch_create_groups'
  post :csv_batch_create_groups, to: 'groups#csv_batch_create_groups_process'

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
