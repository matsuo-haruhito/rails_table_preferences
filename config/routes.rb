# frozen_string_literal: true

RailsTablePreferences::Engine.routes.draw do
  scope "preferences/:table_key" do
    get "/", to: "preferences#index", as: :preferences
    post "/", to: "preferences#create", as: :create_preference
    get "/:name", to: "preferences#show", as: :preference
    patch "/:name", to: "preferences#update", as: :update_preference
    put "/:name", to: "preferences#update", as: :replace_preference
    delete "/:name", to: "preferences#destroy", as: :destroy_preference
  end
end
