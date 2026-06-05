# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  describe "resource table row hooks" do
    let(:order_row_class) { Struct.new(:customer_name) }
    let(:columns) do
      [
        {
          "key" => "customer_name",
          "label" => "Customer",
          "visible" => true,
          "filter" => { "type" => "text" }
        }
      ]
    end
    let(:table_state) { { "visible_columns" => columns } }
    let(:settings) { { "columns" => [], "filters" => {}, "sorts" => [] } }

    def render_resource_table(records)
      render partial: "rails_table_preferences/resource_table", locals: {
        records: records,
        model: nil,
        table_key: "orders",
        name: "default",
        settings: settings,
        columns: columns,
        table_state: table_state,
        profile: nil,
        caption: nil,
        options: { render_editor: false }
      }
    end

    it "adds the stable row hook to each non-empty flat resource table row" do
      render_resource_table([
        order_row_class.new("Acme"),
        order_row_class.new("Beta")
      ])

      expect(rendered.scan('data-rails-table-preferences-resource-row="true"').size).to eq(2)
      expect(rendered).to include('data-rails-table-preferences-column-key="customer_name"')
      expect(rendered).to include('data-rails-table-preferences-filter-type="text"')
    end

    it "does not add the record row hook to the empty state row" do
      render_resource_table([])

      expect(rendered).to include('class="rails-table-preferences-resource-table__empty-row"')
      expect(rendered).not_to include("data-rails-table-preferences-resource-row")
    end
  end
end
