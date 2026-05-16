# frozen_string_literal: true

RSpec.describe "RailsTablePreferences::Preferences", type: :request do
  let(:user) { User.create!(name: "User 1") }

  before do
    Thread.current[:rails_table_preferences_current_user] = user
  end

  describe "GET /rails_table_preferences/preferences/:table_key/:name" do
    it "returns default settings when a preference does not exist" do
      get "/rails_table_preferences/preferences/orders/default"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        "table_key" => "orders",
        "name" => "default",
        "default" => false,
        "settings" => {
          "columns" => [],
          "filters" => {},
          "sorts" => []
        }
      )
    end
  end

  describe "PATCH /rails_table_preferences/preferences/:table_key/:name" do
    it "creates a preference for the current user" do
      patch "/rails_table_preferences/preferences/orders/default", params: {
        settings: {
          columns: [
            {
              key: "customer_code",
              visible: false,
              order: "10",
              width: "120"
            }
          ]
        }
      }

      expect(response).to have_http_status(:ok)
      preference = RailsTablePreferences::Preference.find_for(user: user, table_key: "orders")
      expect(preference.settings["columns"]).to eq(
        [
          {
            "key" => "customer_code",
            "visible" => false,
            "order" => 10,
            "width" => 120,
            "pinned" => false
          }
        ]
      )
    end
  end
end
