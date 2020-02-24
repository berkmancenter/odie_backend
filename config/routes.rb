# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users

  resources :cohorts, only: [:index, :show]
  resources :search_queries, only: [:index, :new, :create, :show]
  resources :cohort_collectors, only: [:index, :new, :create, :show] do
    post :monitor, to: 'cohort_collectors#monitor'
    post :create_cohort, to: 'cohort_collectors#create_cohort'
  end

  defaults format: :json do
    resources :cohorts, only: [:index, :show]
  end

  root to: 'home#index', as: 'home'
end
