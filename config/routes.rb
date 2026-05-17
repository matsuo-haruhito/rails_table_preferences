# frozen_string_literal: true

RailsTablePreferences::Engine.routes.draw do
  scope "preferences/:table_key" do
    get "/", to: "preferences#index", as: :preferences
    post "/", to: "preferences#create", as: nil
    get "/:name", to: "preferences#show", as: :preference
    patch "/:name", to: "preferences#update", as: nil
    put "/:name", to: "preferences#update", as: nil
    delete "/:name", to: "preferences#destroy", as: nil
  end
end
