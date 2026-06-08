# frozen_string_literal: true

RSpec.describe RailsTablePreferences::ColumnDefinition do
  it "treats fixed as an alias for pinned" do
    column = described_class.new(key: :order_no, label: "受注番号", fixed: true)

    expect(column.to_h).to include(
      "key" => "order_no",
      "pinned" => true
    )
  end

  it "keeps pinned when fixed is not provided" do
    column = described_class.new(key: :order_no, label: "受注番号", pinned: true)

    expect(column.to_h["pinned"]).to eq(true)
  end

  it "lets fixed override pinned when both are provided" do
    column = described_class.new(key: :order_no, label: "受注番号", pinned: true, fixed: false)

    expect(column.to_h["pinned"]).to eq(false)
  end

  it "normalizes export key metadata" do
    column = described_class.new(key: :customer_id, export_key: :customer_name, label: "得意先")

    expect(column.to_h).to include(
      "key" => "customer_id",
      "export_key" => "customer_name"
    )
  end

  it "omits blank export key metadata" do
    column = described_class.new(key: :customer_id, export_key: "", label: "得意先")

    expect(column.to_h).not_to have_key("export_key")
  end

  it "normalizes column width boundary metadata" do
    column = described_class.new(
      key: :memo,
      label: "備考",
      min_width: "80",
      max_width: "320"
    )

    expect(column.to_h).to include(
      "min_width" => 80,
      "max_width" => 320
    )
  end

  it "omits non-positive column width boundary metadata" do
    min_column = described_class.new(key: :memo, label: "備考", min_width: 0)
    max_column = described_class.new(key: :memo, label: "備考", max_width: -1)

    expect(min_column.to_h).not_to have_key("min_width")
    expect(max_column.to_h).not_to have_key("max_width")
  end

  it "normalizes hash group metadata" do
    column = described_class.new(
      key: :customer_name,
      label: "得意先名",
      group: { key: :customer, label: "得意先情報" }
    )

    expect(column.to_h["group"]).to eq(
      "key" => "customer",
      "label" => "得意先情報"
    )
  end

  it "normalizes shorthand group metadata" do
    column = described_class.new(key: :customer_name, label: "得意先名", group: :customer)

    expect(column.to_h["group"]).to eq(
      "key" => "customer",
      "label" => "customer"
    )
  end

  it "normalizes select filter label/value option metadata" do
    column = described_class.new(
      key: :status,
      label: "状態",
      filter: { type: :select, options: [{ value: :pending, label: "未出荷" }, "出荷済"] }
    )

    expect(column.to_h["filter"]).to eq(
      "type" => "select",
      "options" => [
        { "value" => "pending", "label" => "未出荷" },
        "出荷済"
      ]
    )
  end
end
