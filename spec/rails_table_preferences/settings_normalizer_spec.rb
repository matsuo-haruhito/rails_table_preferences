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

    it "keeps only positive numeric column boundaries explicit" do
      settings = {
        columns: [
          {
            key: :customer_code,
            order: "-1",
            width: 0,
            truncate: "999999999999"
          }
        ]
      }

      expect(described_class.call(settings)["columns"]).to eq(
        [
          {
            "key" => "customer_code",
            "visible" => true,
            "truncate" => 999_999_999_999,
            "pinned" => false
          }
        ]
      )
    end

    it "drops invalid numeric column values without changing the column" do
      settings = {
        columns: [
          {
            key: :customer_code,
            order: "first",
            width: "12.5",
            truncate: nil
          }
        ]
      }

      expect(described_class.call(settings)["columns"]).to eq(
        [
          {
            "key" => "customer_code",
            "visible" => true,
            "pinned" => false
          }
        ]
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

    it "normalizes filters into the neutral adapter format" do
      settings = {
        filters: {
          customer_name: { operator: :contains, value: "山田" },
          status: { predicate: :in, values: %w[未出荷 出荷済] },
          delivery_date: { operator: :between, from: "2026-01-01", to: "2026-01-31" }
        }
      }

      expect(described_class.call(settings)["filters"]).to eq(
        "customer_name" => {
          "operator" => "contains",
          "value" => "山田"
        },
        "status" => {
          "operator" => "in",
          "values" => %w[未出荷 出荷済]
        },
        "delivery_date" => {
          "operator" => "between",
          "from" => "2026-01-01",
          "to" => "2026-01-31"
        }
      )
    end

    it "drops filters without a key" do
      settings = {
        filters: {
          "" => { operator: :equals, value: "ignored" },
          "   " => { operator: :equals, value: "also ignored" },
          customer_name: { operator: :contains, value: "山田" },
          status: { operator: :matches_anything, value: "出荷済" }
        }
      }

      expect(described_class.call(settings)["filters"]).to eq(
        "customer_name" => {
          "operator" => "contains",
          "value" => "山田"
        },
        "status" => {
          "operator" => "matches_anything",
          "value" => "出荷済"
        }
      )
    end

    it "drops filters without an operator" do
      settings = {
        filters: {
          customer_name: { value: "山田" },
          status: { operator: :equals, value: "出荷済" }
        }
      }

      expect(described_class.call(settings)["filters"]).to eq(
        "status" => {
          "operator" => "equals",
          "value" => "出荷済"
        }
      )
    end

    it "normalizes scalar filter values into values arrays for multi-value operators" do
      settings = {
        filters: {
          status: { operator: :in, values: "出荷済" }
        }
      }

      expect(described_class.call(settings)["filters"]).to eq(
        "status" => {
          "operator" => "in",
          "values" => ["出荷済"]
        }
      )
    end

    it "normalizes sorts" do
      settings = {
        sorts: [
          { key: :delivery_date, direction: :DESC },
          { column: :customer_code, dir: :asc }
        ]
      }

      expect(described_class.call(settings)["sorts"]).to eq(
        [
          { "key" => "delivery_date", "direction" => "desc" },
          { "key" => "customer_code", "direction" => "asc" }
        ]
      )
    end

    it "drops invalid sorts" do
      settings = {
        sorts: [
          { key: :delivery_date, direction: :sideways },
          { direction: :asc },
          { key: :customer_code, direction: :asc }
        ]
      }

      expect(described_class.call(settings)["sorts"]).to eq(
        [
          { "key" => "customer_code", "direction" => "asc" }
        ]
      )
    end
  end
end
