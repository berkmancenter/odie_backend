# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users

  resources :cohorts, only: [:index, :new, :create, :show] do
    post :collect_data, to: 'cohorts#collect_data'
  end
  resources :search_queries, only: [:index, :new, :create, :show]
  resources :cohort_collectors, only: [:index, :new, :create, :show] do
    post :monitor, to: 'cohort_collectors#monitor'
    post :create_cohort, to: 'cohort_collectors#create_cohort'
  end

  devise_for :api_users,
             defaults: { format: :json },
             class_name: 'ApiUser',
             skip: %i[
               registrations invitations
               passwords confirmations
               unlocks
             ],
             path: '',
             path_names: {
               sign_in: 'login',
               sign_out: 'logout'
             }
  devise_scope :api_user do
    get 'login', to: 'devise/sessions#new'
    delete 'logout', to: 'devise/sessions#destroy'
  end

  root to: 'home#index', as: 'home'
end
