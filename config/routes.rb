Intel::Engine.routes.draw do
  get "searches/recent"
  root to: "searches#index"
end
