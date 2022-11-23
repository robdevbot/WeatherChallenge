Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'forecast#index'
  post '/forecast' => 'forecast#create'
  get '/forecast/:id' => 'forecast#show'
end
