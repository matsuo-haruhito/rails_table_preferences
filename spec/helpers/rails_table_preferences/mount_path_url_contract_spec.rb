# frozen_string_literal: true

RSpec.describe "RailsTablePreferences mount path URL contract", type: :helper do
  around do |example|
    original_mount_path = RailsTablePreferences.configuration.mount_path
    example.run
  ensure
    RailsTablePreferences.configuration.mount_path = original_mount_path
  end

  it "uses the configured mount path and encodes table keys and preset names" do
    RailsTablePreferences.configuration.mount_path = "/tenant/preferences_engine/"

    expect(helper.table_preferences_collection_url(table_key: "order details/2026")).to eq(
      "/tenant/preferences_engine/preferences/order%20details%2F2026"
    )
    expect(helper.table_preferences_preference_url(table_key: "order details/2026", name: "my default/qa")).to eq(
      "/tenant/preferences_engine/preferences/order%20details%2F2026/my%20default%2Fqa"
    )
  end

  it "emits table root URL data values from the configured mount path" do
    RailsTablePreferences.configuration.mount_path = "/tenant/preferences_engine"

    html = helper.table_preferences_table_tag(
      table_key: "order details",
      name: "team default",
      columns: [helper.table_preferences_column(:customer_code, label: "Customer Code")]
    ) { "content" }

    expect(html).to include('data-rails-table-preferences-collection-url-value="/tenant/preferences_engine/preferences/order%20details"')
    expect(html).to include('data-rails-table-preferences-url-value="/tenant/preferences_engine/preferences/order%20details/team%20default"')
  end

  it "passes editor URL values from the configured mount path" do
    RailsTablePreferences.configuration.mount_path = "/tenant/preferences_engine"

    html = helper.table_preferences_editor(
      table_key: "order details",
      name: "team default",
      columns: [helper.table_preferences_column(:customer_code, label: "Customer Code")]
    )

    expect(html).to include('rails-table-preferences-collection-url-value="/tenant/preferences_engine/preferences/order%20details"')
    expect(html).to include('rails-table-preferences-url-value="/tenant/preferences_engine/preferences/order%20details/team%20default"')
  end
end
