Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'attendances#index'
  devise_for :administrators, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  resources :attendances, only: %i(index update)
end
