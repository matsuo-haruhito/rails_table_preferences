# frozen_string_literal: true

RSpec.describe RailsTablePreferences::ColumnDefinition do
  it "treats fixed as an alias for pinned" do
    column = described_class.new(key: :order_no, fixed: true)

    expect(column.to_h).to include(
      "key" => "order_no",
      "pinned" => true
    )
  end

  it "keeps pinned when fixed is not provided" do
    column = described_class.new(key: :order_no, pinned: true)

    expect(column.to_h["pinned"]).to eq(true)
  end

  it "lets fixed override pinned when both are provided" do
    column = described_class.new(key: :order_no, pinned: true, fixed: false)

    expect(column.to_h["pinned"]).to eq(false)
  end

  it "normalizes hash group metadata" do
    column = described_class.new(
      key: :customer_name,
      group: { key: :customer, label: "得意先情報" }
    )

    expect(column.to_h["group"]).to eq(
      "key" => "customer",
      "label" => "得意先情報"
    )
  end

  it "normalizes shorthand group metadata" do
    column = described_class.new(key: :customer_name, group: :customer)

    expect(column.to_h["group"]).to eq(
      "key" => "customer",
      "label" => "customer"
    )
  end
end
