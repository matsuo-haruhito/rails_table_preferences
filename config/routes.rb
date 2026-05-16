# frozen_string_literal: true

RailsTablePreferences::Engine.routes.draw do
  scope "preferences/:table_key" do
    get "/(:name)", to: "preferences#show", as: :preference
    patch "/(:name)", to: "preferences#update"
    put "/(:name)", to: "preferences#update"
  end
end
