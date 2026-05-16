# frozen_string_literal: true

RailsTablePreferences::Engine.routes.draw do
  scope "preferences/:table_key" do
    get "/", to: "preferences#index", as: :preferences
    post "/", to: "preferences#create"
    get "/(:name)", to: "preferences#show", as: :preference
    patch "/(:name)", to: "preferences#update"
    put "/(:name)", to: "preferences#update"
    delete "/(:name)", to: "preferences#destroy"
  end
end
