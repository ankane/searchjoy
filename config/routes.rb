Intel::Engine.routes.draw do
  resources :searches, only: [:index]
  get "searches/recent"
  root to: "searches#stream"
end
