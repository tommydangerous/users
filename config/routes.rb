Rails.application.routes.draw do
  resources :users, defaults: { format: :json }
end
