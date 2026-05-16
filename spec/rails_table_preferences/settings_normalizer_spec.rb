# frozen_string_literal: true

RSpec.describe RailsTablePreferences::SettingsNormalizer do
  describe ".call" do
    it "returns default settings for nil" do
      expect(described_class.call(nil)).to eq(
        "columns" => [],
        "filters" => {},
        "sorts" => []
      )
    end

    it "normalizes current column keys" do
      settings = {
        columns: [
          {
            key: :customer_code,
            visible: "1",
            order: "10",
            width: "120",
            truncate: "20",
            pinned: "0"
          }
        ]
      }

      expect(described_class.call(settings)).to eq(
        "columns" => [
          {
            "key" => "customer_code",
            "visible" => true,
            "order" => 10,
            "width" => 120,
            "truncate" => 20,
            "pinned" => false
          }
        ],
        "filters" => {},
        "sorts" => []
      )
    end

    it "normalizes legacy ColumnAdjustment keys" do
      settings = {
        columns: [
          {
            column_name: "customer_code",
            display_flag: false,
            display_order: "30",
            width: "200"
          }
        ]
      }

      expect(described_class.call(settings)["columns"]).to eq(
        [
          {
            "key" => "customer_code",
            "visible" => false,
            "order" => 30,
            "width" => 200,
            "pinned" => false
          }
        ]
      )
    end

    it "drops columns without a key" do
      settings = { columns: [{ width: 100 }] }

      expect(described_class.call(settings)["columns"]).to eq([])
    end
  end
end
