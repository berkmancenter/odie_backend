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

  namespace :admin do
    resources :media_sources

    root to: 'media_sources#index'
  end

  get 'cohorts(/:id)', to: 'cohort#show', as: :cohort_show
  get 'activate/:id', to: 'twitter_confs#new', as: :activate
  resources :data_collections, only: [:new]

  defaults format: :json do
    resources :cohorts, only: [:index, :show]
  end
end
