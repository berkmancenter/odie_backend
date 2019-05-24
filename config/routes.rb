Rails.application.routes.draw do
  devise_for :users
  namespace :admin do
    resources :media_sources

    root to: 'media_sources#index'
  end

  devise_scope :user do
    root to: 'devise/sessions#new'
  end

  resource :twitter_conf, only: [:new]
end
