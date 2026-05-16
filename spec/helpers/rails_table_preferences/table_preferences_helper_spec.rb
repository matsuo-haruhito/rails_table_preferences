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

  describe "#table_preferences_collection_url" do
    it "builds a collection URL for table presets" do
      expect(helper.table_preferences_collection_url(table_key: :orders)).to eq(
        "/rails_table_preferences/preferences/orders"
      )
    end
  end

  describe "#table_preferences_data_attributes" do
    it "returns Stimulus data attributes for a table" do
      attributes = helper.table_preferences_data_attributes(
        table_key: :orders,
        columns: [helper.table_preferences_column(:customer_code, label: "Customer Code", default_width: 120)]
      )

      expect(attributes).to include(
        controller: "rails-table-preferences",
        rails_table_preferences_table_key_value: "orders",
        rails_table_preferences_name_value: "default",
        rails_table_preferences_url_value: "/rails_table_preferences/preferences/orders/default",
        rails_table_preferences_collection_url_value: "/rails_table_preferences/preferences/orders"
      )
      expect(JSON.parse(attributes[:rails_table_preferences_settings_value])).to eq(
        "columns" => [],
        "filters" => {},
        "sorts" => []
      )
      expect(JSON.parse(attributes[:rails_table_preferences_columns_value])).to eq(
        [
          {
            "key" => "customer_code",
            "label" => "Customer Code",
            "visible" => true,
            "width" => 120,
            "pinned" => false
          }
        ]
      )
    end
  end

  describe "#table_preferences_column" do
    it "builds a column definition hash" do
      expect(helper.table_preferences_column(:customer_code, label: "Customer Code", default_order: 10)).to eq(
        "key" => "customer_code",
        "label" => "Customer Code",
        "visible" => true,
        "order" => 10,
        "pinned" => false
      )
    end
  end

  describe "#table_preferences_editor" do
    it "renders an editor container with action buttons" do
      html = helper.table_preferences_editor(table_key: :orders, columns: [:customer_code])

      expect(html).to include("rails-table-preferences-editor")
      expect(html).to include("rails-table-preferences#applyFromEditor")
      expect(html).to include("rails-table-preferences#saveFromEditor")
      expect(html).to include("rails-table-preferences#createPresetFromEditor")
      expect(html).to include("rails-table-preferences#deletePreset")
      expect(html).to include("rails-table-preferences#resetEditor")
    end

    it "renders a preset name input" do
      html = helper.table_preferences_editor(table_key: :orders, name: "inspection", columns: [:customer_code])

      expect(html).to include("value=\"inspection\"")
      expect(html).to include("rails-table-preferences-target=\"presetName\"")
    end

    it "renders a container used for draggable editor rows" do
      html = helper.table_preferences_editor(table_key: :orders, columns: [:customer_code])

      expect(html).to include("rails-table-preferences-editor__rows")
      expect(html).to include("rails-table-preferences-target=\"editorRows\"")
    end
  end
end
