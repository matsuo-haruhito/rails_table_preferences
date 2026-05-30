# frozen_string_literal: true

RSpec.describe "table preferences table data attribute merging", type: :helper do
  it "keeps host app data while merging controller tokens" do
    html = helper.table_preferences_table_tag(
      table_key: :orders,
      columns: [helper.table_preferences_column(:customer_code, label: "Customer Code")],
      data: {
        "controller" => "orders-table rails-table-preferences",
        turbo_frame: "orders-frame",
        analytics_scope: "orders-index"
      }
    ) { "content" }

    expect(html).to include('data-controller="orders-table rails-table-preferences"')
    expect(html).to include('data-turbo-frame="orders-frame"')
    expect(html).to include('data-analytics-scope="orders-index"')
    expect(html).to include('data-rails-table-preferences-table-key-value="orders"')
    expect(html).not_to include('rails-table-preferences rails-table-preferences')
  end
end
