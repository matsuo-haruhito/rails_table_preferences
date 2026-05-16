# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  describe "#table_preferences_preference_url" do
    it "builds a URL using the configured mount path" do
      RailsTablePreferences.configuration.mount_path = "/preferences_engine"

      expect(helper.table_preferences_preference_url(table_key: :orders, name: "default")).to eq(
        "/preferences_engine/preferences/orders/default"
      )
    end

    it "URL-encodes table key and name" do
      expect(helper.table_preferences_preference_url(table_key: "order details", name: "my default")).to eq(
        "/rails_table_preferences/preferences/order%20details/my%20default"
      )
    end
  end

  describe "#table_preferences_data_attributes" do
    it "returns Stimulus data attributes for a table" do
      attributes = helper.table_preferences_data_attributes(table_key: :orders)

      expect(attributes).to include(
        controller: "rails-table-preferences",
        rails_table_preferences_table_key_value: "orders",
        rails_table_preferences_name_value: "default",
        rails_table_preferences_url_value: "/rails_table_preferences/preferences/orders/default"
      )
      expect(JSON.parse(attributes[:rails_table_preferences_settings_value])).to eq(
        "columns" => [],
        "filters" => {},
        "sorts" => []
      )
    end
  end
end
