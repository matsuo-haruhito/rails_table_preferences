# frozen_string_literal: true

RailsTablePreferences::Engine.routes.draw do
  scope "preferences/:table_key" do
    get "/", to: "preferences#index", as: :table_preferences_index
    post "/", to: "preferences#create", as: :table_preferences_create
    get "/:name", to: "preferences#show", as: :table_preference
    patch "/:name", to: "preferences#update", as: :table_preference_update
    put "/:name", to: "preferences#update", as: :table_preference_replace
    delete "/:name", to: "preferences#destroy", as: :table_preference_destroy
  end
end
