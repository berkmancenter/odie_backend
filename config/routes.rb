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

  get 'media_sources/data', to: 'media_sources#data', as: :media_source_data
  get 'activate/:id', to: 'twitter_confs#new', as: :activate
  resources :data_collections, only: [:new]

  defaults format: :json do
    resources :media_sources, only: [:index, :show, :data]
  end
end
