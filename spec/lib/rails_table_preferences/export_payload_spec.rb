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

  it "keeps display column keys separate from export key metadata" do
    columns = [
      { key: :customer_name, label: "得意先名", group: { key: :customer, label: "得意先情報" }, export_key: :customer_display_name }
    ]

    payload = described_class.call(settings: {}, columns: columns)

    expect(payload["column_keys"]).to eq(%w[customer_name])
    expect(payload["columns"].first["group"]).to eq("key" => :customer, "label" => "得意先情報")
    expect(payload["columns"].first["export_key"]).to eq(:customer_display_name)
  end
end
