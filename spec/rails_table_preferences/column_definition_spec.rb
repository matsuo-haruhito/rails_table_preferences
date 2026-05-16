# frozen_string_literal: true

RSpec.describe RailsTablePreferences::ColumnDefinition do
  describe "#to_h" do
    it "builds a serializable column definition" do
      definition = described_class.new(
        key: :customer_code,
        label: "Customer Code",
        default_visible: "1",
        default_order: "10",
        default_width: "120",
        default_truncate: "20",
        pinned: "0"
      )

      expect(definition.to_h).to eq(
        "key" => "customer_code",
        "label" => "Customer Code",
        "visible" => true,
        "order" => 10,
        "width" => 120,
        "truncate" => 20,
        "pinned" => false
      )
    end

    it "uses a humanized label by default" do
      definition = described_class.new(key: :customer_code)

      expect(definition.to_h["label"]).to eq("Customer code")
    end
  end
end
