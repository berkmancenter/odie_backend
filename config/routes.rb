# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users

  devise_scope :user do
    unauthenticated do
      root to: 'devise/sessions#new'
    end

    authenticated do
      root to: 'home#index'
    end
  end

  resources :cohorts, only: [:show]
  resources :search_queries, only: [:index, :new, :create, :show]
  resources :cohort_collectors, only: [:index, :new, :create, :show]

  defaults format: :json do
    resources :cohorts, only: [:index, :show]
  end
end
