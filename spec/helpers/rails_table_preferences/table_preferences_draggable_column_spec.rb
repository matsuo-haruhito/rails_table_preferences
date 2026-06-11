# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  before do
    RailsTablePreferences.configuration.unresolved_label_behavior = :humanize
  end

  it "emits draggable metadata from table_preferences_column" do
    column = helper.table_preferences_column(:help_link, label: "Help", draggable: false)

    expect(column).to include(
      "key" => "help_link",
      "draggable" => false
    )
  end

  it "preserves draggable metadata from hash column definitions" do
    columns = helper.table_preferences_columns([
      { key: :help_link, label: "Help", draggable: false },
      { key: :order_no, label: "Order no" }
    ])

    expect(columns).to include(
      include("key" => "help_link", "draggable" => false),
      include("key" => "order_no")
    )
    expect(columns.find { |column| column["key"] == "order_no" }).not_to have_key("draggable")
  end

  it "includes draggable metadata in columns JSON" do
    attributes = helper.table_preferences_data_attributes(
      table_key: :orders,
      columns: [helper.table_preferences_column(:help_link, label: "Help", draggable: false)]
    )

    expect(JSON.parse(attributes[:rails_table_preferences_columns_value])).to eq(
      [
        {
          "key" => "help_link",
          "label" => "Help",
          "visible" => true,
          "pinned" => false,
          "draggable" => false
        }
      ]
    )
  end
end
