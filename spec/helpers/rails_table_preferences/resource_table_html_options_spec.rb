# frozen_string_literal: true

require "ostruct"

RSpec.describe "resource table HTML options", type: :helper do
  def render_resource_table(options: {})
    columns = [helper.table_preferences_column(:name, label: "Name")]
    table_state = helper.table_preferences_state(settings: {}, columns: columns)

    render partial: "rails_table_preferences/resource_table", locals: {
      records: [OpenStruct.new(name: "Ada")],
      model: nil,
      table_key: "orders",
      name: "default",
      settings: {},
      columns: columns,
      table_state: table_state,
      profile: nil,
      options: options
    }

    rendered
  end

  it "passes basic HTML attributes through to the default resource table" do
    html = render_resource_table(
      options: {
        id: "orders-table",
        class: "orders-table",
        data: { turbo_frame: "orders-frame" },
        aria: { label: "Orders" }
      }
    )

    expect(html).to include('id="orders-table"')
    expect(html).to include('class="rails-table-preferences-resource-table orders-table"')
    expect(html).to include('data-turbo-frame="orders-frame"')
    expect(html).to include('aria-label="Orders"')
  end

  it "keeps Rails Table Preferences controller data attributes authoritative" do
    html = helper.table_preferences_table_tag(
      table_key: :orders,
      columns: [:name],
      data: {
        turbo_frame: "orders-frame",
        rails_table_preferences_table_key_value: "host-value"
      }
    ) { "" }

    expect(html).to include('data-turbo-frame="orders-frame"')
    expect(html).to include('data-controller="rails-table-preferences"')
    expect(html).to include('data-rails-table-preferences-table-key-value="orders"')
    expect(html).not_to include('data-rails-table-preferences-table-key-value="host-value"')
  end
end
