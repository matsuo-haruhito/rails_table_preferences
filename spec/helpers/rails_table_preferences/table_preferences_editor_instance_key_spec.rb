# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  describe "#table_preferences_editor editor_instance_key" do
    it "uses a deterministic internal id prefix when editor_instance_key is provided" do
      html = helper.table_preferences_editor(
        table_key: :orders,
        name: "inspection",
        columns: [:customer_code],
        editor_instance_key: "snapshot A"
      )

      id_prefix = "rails-table-preferences-orders-inspection-snapshot-a"
      expect(html).to include("id=\"#{id_prefix}-preset-select\"")
      expect(html).to include("id=\"#{id_prefix}-preset-name\"")
      expect(html).to include("id=\"#{id_prefix}-preset-select-hint\"")
      expect(html).to include("id=\"#{id_prefix}-action-hint\"")
      expect(html).to include("aria-describedby=\"#{id_prefix}-preset-select-hint\"")
    end

    it "lets host apps separate multiple editor instances with different keys" do
      first_html = helper.table_preferences_editor(
        table_key: :orders,
        name: "inspection",
        columns: [:customer_code],
        editor_instance_key: "left pane"
      )
      second_html = helper.table_preferences_editor(
        table_key: :orders,
        name: "inspection",
        columns: [:customer_code],
        editor_instance_key: "right pane"
      )

      expect(first_html).to include("rails-table-preferences-orders-inspection-left-pane-preset-select")
      expect(second_html).to include("rails-table-preferences-orders-inspection-right-pane-preset-select")
    end

    it "keeps the random collision-avoidance suffix when editor_instance_key is omitted" do
      first_html = helper.table_preferences_editor(table_key: :orders, name: "inspection", columns: [:customer_code])
      second_html = helper.table_preferences_editor(table_key: :orders, name: "inspection", columns: [:customer_code])

      first_id = first_html.match(/id=\"(rails-table-preferences-orders-inspection-[^-]+-preset-select)\"/)[1]
      second_id = second_html.match(/id=\"(rails-table-preferences-orders-inspection-[^-]+-preset-select)\"/)[1]

      expect(first_id).not_to eq(second_id)
    end
  end
end
