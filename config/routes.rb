# frozen_string_literal: true

Rails.application.routes.draw do
  resources :cohorts, only: [:index, :new, :create, :show]
  resources :timespans, only: [:index]

  get 'cohort_summaries', to: 'cohort_summaries#index', as: :cohort_summaries
  get 'cohort/:id/timespan/:timespan_id', to: 'cohort_summaries#show'
  put 'cohort/:id/timespan/:timespan_id', to: 'cohort_summaries#update', as: :cohort_summary_receiver

  get 'cohort_comparisons', to: 'cohort_comparisons#index', as: :cohort_comparisons
  get 'cohort/:cohort_a_id/timespan/:timespan_a_id/cohort/:cohort_b_id/timespan/:timespan_b_id',
    to: 'cohort_comparisons#show'
  put 'cohort/:cohort_a_id/timespan/:timespan_a_id/cohort/:cohort_b_id/timespan/:timespan_b_id',
    to: 'cohort_comparisons#update', as: :cohort_comparison_receiver
  #put 'cohort/:cohort_a_id/timespan/:timespan_a_id/cohort/:cohort_b_id/timespan/:timespan_b_id',
    #to: 'cohort_comparisons#update', as: :cohort_comparison_receiver

  devise_for :users
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

  match '*all', to: 'application#cors_preflight_check', via: :options
end
