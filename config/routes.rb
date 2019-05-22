Rails.application.routes.draw do
  namespace :admin do
    resources :media_sources

    root to: "media_sources#index"
  end
end
