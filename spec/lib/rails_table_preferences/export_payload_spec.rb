# frozen_string_literal: true

RSpec.describe RailsTablePreferences::ExportPayload do
  it "returns visible columns in preference order" do
    columns = [
      { key: :order_no, label: "受注番号", default_order: 10 },
      { key: :customer_name, label: "得意先名", default_order: 20 },
      { key: :internal_cost, label: "内部原価", default_order: 30 }
    ]
    settings = {
      columns: [
        { key: :customer_name, visible: true, order: 10 },
        { key: :order_no, visible: true, order: 20 },
        { key: :internal_cost, visible: false, order: 30 }
      ]
    }

    payload = described_class.call(settings: settings, columns: columns)

    expect(payload["column_keys"]).to eq(%w[customer_name order_no])
    expect(payload["export_keys"]).to eq(%w[customer_name order_no])
    expect(payload["headers"]).to eq(%w[得意先名 受注番号])
  end

  it "can include hidden columns" do
    columns = [
      { key: :order_no, label: "受注番号" },
      { key: :internal_cost, label: "内部原価" }
    ]
    settings = { columns: [{ key: :internal_cost, visible: false, order: 10 }] }

    payload = described_class.call(settings: settings, columns: columns, include_hidden: true)

    expect(payload["column_keys"]).to include("internal_cost")
    expect(payload["export_keys"]).to include("internal_cost")
  end

  it "keeps direct payload settings normalized while export columns come from current column definitions" do
    columns = [
      { key: :order_no, label: "受注番号" },
      { key: :customer_name, label: "得意先名" }
    ]
    settings = {
      columns: [
        { key: :deleted_column, visible: true, order: 1 },
        { key: :customer_name, visible: false, order: 2 },
        { key: :order_no, visible: true, order: 3 }
      ],
      filters: {
        deleted_column: { operator: "contains", value: "archived" },
        order_no: { operator: "contains", value: "A-001" }
      },
      sorts: [
        { key: :deleted_column, direction: :desc },
        { key: :order_no, direction: :asc }
      ]
    }

    payload = described_class.call(settings: settings, columns: columns)
    hidden_payload = described_class.call(settings: settings, columns: columns, include_hidden: true)

    expect(payload["column_keys"]).to eq(%w[order_no])
    expect(payload["headers"]).to eq(%w[受注番号])
    expect(payload["columns"].map { |column| column["key"] }).to eq(%w[order_no])

    expect(hidden_payload["column_keys"]).to eq(%w[customer_name order_no])
    expect(hidden_payload["headers"]).to eq(%w[得意先名 受注番号])

    expect(payload["settings"].fetch("columns").map { |column| column["key"] }).to eq(%w[deleted_column customer_name order_no])
    expect(payload["settings"].fetch("filters").keys).to contain_exactly("deleted_column", "order_no")
    expect(payload["settings"].fetch("sorts").map { |sort| sort["key"] }).to eq(%w[deleted_column order_no])
  end

  it "prefers current column metadata over stale saved column metadata" do
    columns = [
      {
        key: :order_no,
        label: "Current order number",
        group: { key: :current_order, label: "Current order group" },
        export_key: :current_order_number
      },
      {
        key: :internal_cost,
        label: "Current internal cost",
        group: { key: :current_finance, label: "Current finance group" },
        export_key: :current_cost_cents
      }
    ]
    settings = {
      columns: [
        {
          key: :internal_cost,
          visible: false,
          order: 10,
          label: "Stale internal cost",
          group: { key: :stale_finance, label: "Stale finance group" },
          export_key: :stale_cost
        },
        {
          key: :order_no,
          visible: true,
          order: 20,
          label: "Stale order number",
          group: { key: :stale_order, label: "Stale order group" },
          export_key: :stale_order_number
        }
      ]
    }

    visible_payload = described_class.call(settings: settings, columns: columns)
    full_payload = described_class.call(settings: settings, columns: columns, include_hidden: true)

    expect(visible_payload["column_keys"]).to eq(%w[order_no])
    expect(visible_payload["headers"]).to eq(["Current order number"])
    expect(visible_payload["export_keys"]).to eq([:current_order_number])
    expect(visible_payload["columns"].first["group"]).to eq("key" => :current_order, "label" => "Current order group")

    expect(full_payload["column_keys"]).to eq(%w[internal_cost order_no])
    expect(full_payload["headers"]).to eq(["Current internal cost", "Current order number"])
    expect(full_payload["export_keys"]).to eq(%i[current_cost_cents current_order_number])
    expect(full_payload["columns"].map { |column| column["group"] }).to eq(
      [
        { "key" => :current_finance, "label" => "Current finance group" },
        { "key" => :current_order, "label" => "Current order group" }
      ]
    )
  end

  it "keeps display column keys separate from export key metadata" do
    columns = [
      { key: :customer_name, label: "得意先名", group: { key: :customer, label: "得意先情報" }, export_key: :customer_display_name }
    ]

    payload = described_class.call(settings: {}, columns: columns)

    expect(payload["column_keys"]).to eq(%w[customer_name])
    expect(payload["export_keys"]).to eq([:customer_display_name])
    expect(payload["columns"].first["group"]).to eq("key" => :customer, "label" => "得意先情報")
    expect(payload["columns"].first["export_key"]).to eq(:customer_display_name)
  end

  it "uses the same filter and order for export keys when hidden columns are included" do
    columns = [
      { key: :order_no, label: "受注番号", export_key: :number_for_export },
      { key: :customer_name, label: "得意先名", export_key: :customer_display_name },
      { key: :internal_cost, label: "内部原価", export_key: :cost_cents }
    ]
    settings = {
      columns: [
        { key: :internal_cost, visible: false, order: 10 },
        { key: :customer_name, visible: true, order: 20 },
        { key: :order_no, visible: true, order: 30 }
      ]
    }

    visible_payload = described_class.call(settings: settings, columns: columns)
    full_payload = described_class.call(settings: settings, columns: columns, include_hidden: true)

    expect(visible_payload["column_keys"]).to eq(%w[customer_name order_no])
    expect(visible_payload["export_keys"]).to eq(%i[customer_display_name number_for_export])
    expect(full_payload["column_keys"]).to eq(%w[internal_cost customer_name order_no])
    expect(full_payload["export_keys"]).to eq(%i[cost_cents customer_display_name number_for_export])
  end
end
