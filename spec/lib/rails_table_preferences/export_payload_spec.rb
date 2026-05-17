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

  it "keeps group and export key metadata" do
    columns = [
      { key: :customer_name, label: "得意先名", group: { key: :customer, label: "得意先情報" }, export_key: :customer_display_name }
    ]

    payload = described_class.call(settings: {}, columns: columns)

    expect(payload["columns"].first["group"]).to eq("key" => :customer, "label" => "得意先情報")
    expect(payload["columns"].first["export_key"]).to eq(:customer_display_name)
  end
end
