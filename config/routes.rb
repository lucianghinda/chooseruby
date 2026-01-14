# frozen_string_literal: true

Rails.application.routes.draw do
  mount_avo

  # Authentication
  resource :session, only: [ :new, :create, :destroy ]

  # Author proposal routes (specific routes must come before dynamic author routes)
  get "/author_proposals/new_author", to: "author_proposals#new_author", as: :new_author_proposal
  get "/author_proposals/:id/success", to: "author_proposals#success", as: :author_proposal_success
  resources :author_proposals, only: [ :new, :create, :show ]

  # Author pages
  get "/authors/search", to: "authors#search", as: :authors_search
  get "/authors/:author_id/propose_edit", to: "author_proposals#new", as: :propose_author_edit
  resources :authors, only: [ :index ], param: :slug
  get "/authors/:slug", to: "authors#show", as: :author

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  # Beginner landing page
  get "/start", to: "entries#start", as: :start

  # Community entry submission routes (specific routes must come before resources)
  get "/entries/new", to: "entries#new", as: :new_entry
  get "/entries/suggestions", to: "entries#suggestions", as: :entries_suggestions
  get "/entries/success", to: "entries#success", as: :entry_success
  post "/entries", to: "entries#create"
  resources :entries, only: :index

  resources :collections, only: %i[index show]
  resources :communities, only: :index
  resources :categories, only: %i[index show], param: :slug

  get "/why-ruby", to: "pages#why_ruby", as: :why_ruby
  get "/mission", to: "pages#mission", as: :mission
  get "/roadmap", to: "pages#roadmap", as: :roadmap

  # Redirect old resource_submission routes to new entry submission routes
  get "/resources/submit", to: redirect("/entries/new"), as: :new_resource_submission
  post "/resources/submit", to: redirect("/entries/new")
  get "/resources/submit/success", to: redirect("/entries/success"), as: :resource_submission_success
  get "/resources/contribute", to: redirect("/entries/new"), as: :resource_submission_guide

  # Resources directory index (must come before type and dynamic slug routes)
  get "/resources", to: "resources#index", as: :resources

  # Resource type browse pages (must come before dynamic slug route)
  get "/resources/type/:type", to: "resource_types#show", as: :resource_type

  # Resource detail pages (dynamic slug route comes last)
  get "/resources/:id", to: "resources#show", as: :resource
end
