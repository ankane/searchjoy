Searchjoy::Engine.routes.draw do
  resources :searches, only: [:index] do
    get "overview", on: :collection
  end
  get "searches/recent"
  root to: "searches#stream"
end
