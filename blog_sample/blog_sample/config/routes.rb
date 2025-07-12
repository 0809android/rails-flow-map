Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users do
        resources :posts do
          resources :comments
        end
      end
      
      resources :posts, only: [:index, :show] do
        resources :comments, only: [:index, :create]
      end
      
      # Additional routes for demonstration
      get 'analytics/users', to: 'analytics#users'
      get 'analytics/posts', to: 'analytics#posts'
      post 'users/:id/follow', to: 'users#follow'
      delete 'users/:id/unfollow', to: 'users#unfollow'
    end
  end
  
  # Health check
  get 'health', to: 'application#health'
end