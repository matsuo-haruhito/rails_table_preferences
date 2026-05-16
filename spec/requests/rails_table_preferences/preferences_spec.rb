# frozen_string_literal: true

RSpec.describe "RailsTablePreferences::Preferences", type: :request do
  let(:user) { User.create!(name: "User 1") }

  before do
    Thread.current[:rails_table_preferences_current_user] = user
  end

  describe "GET /rails_table_preferences/preferences/:table_key" do
    it "returns preferences for the current user and table" do
      RailsTablePreferences::Preference.create!(
        user: user,
        table_key: "orders",
        name: "default",
        default_flag: true,
        settings: { "columns" => [] }
      )
      RailsTablePreferences::Preference.create!(
        user: user,
        table_key: "orders",
        name: "inspection",
        settings: { "columns" => [] }
      )

      get "/rails_table_preferences/preferences/orders"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["preferences"].map { |preference| preference["name"] }).to eq(%w[default inspection])
    end
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

  describe "POST /rails_table_preferences/preferences/:table_key" do
    it "creates a named preference" do
      post "/rails_table_preferences/preferences/orders", params: {
        name: "inspection",
        settings: {
          columns: [
            {
              key: "customer_code",
              visible: true,
              order: "10"
            }
          ]
        }
      }

      expect(response).to have_http_status(:created)
      preference = RailsTablePreferences::Preference.find_for(user: user, table_key: "orders", name: "inspection")
      expect(preference).to be_present
      expect(preference.settings["columns"].first["key"]).to eq("customer_code")
    end

    it "clears other default flags when creating a new default" do
      existing = RailsTablePreferences::Preference.create!(
        user: user,
        table_key: "orders",
        name: "default",
        default_flag: true,
        settings: { "columns" => [] }
      )

      post "/rails_table_preferences/preferences/orders", params: {
        name: "inspection",
        default: true,
        settings: { columns: [] }
      }

      expect(response).to have_http_status(:created)
      expect(existing.reload.default_flag).to eq(false)
      expect(RailsTablePreferences::Preference.find_for(user: user, table_key: "orders", name: "inspection").default_flag).to eq(true)
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

  describe "DELETE /rails_table_preferences/preferences/:table_key/:name" do
    it "deletes a named preference" do
      RailsTablePreferences::Preference.create!(
        user: user,
        table_key: "orders",
        name: "inspection",
        settings: { "columns" => [] }
      )

      delete "/rails_table_preferences/preferences/orders/inspection"

      expect(response).to have_http_status(:no_content)
      expect(RailsTablePreferences::Preference.find_for(user: user, table_key: "orders", name: "inspection")).to be_nil
    end
  end
end
