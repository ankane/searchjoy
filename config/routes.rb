Searchjoy::Engine.routes.draw do
  resources :searches, only: [:index] do
    get "overview", on: :collection
  end
  post "searches/overview"
  post "searches/index"
  get "searches/recent"
  root to: "searches#stream"
end
