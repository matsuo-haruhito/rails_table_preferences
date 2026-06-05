# frozen_string_literal: true

RSpec.describe RailsTablePreferences::Adapters::Ransack do
  describe ".filter_params" do
    it "converts text contains filters to Ransack predicates" do
      expect(
        described_class.filter_params(
          customer_name: { operator: :contains, value: "山田" }
        )
      ).to eq("customer_name_cont" => "山田")
    end

    it "uses column filter param metadata when provided" do
      expect(
        described_class.filter_params(
          { customer_id: { operator: :contains, value: "山田" } },
          columns: [
            { key: :customer_id, filter: { param: :customer_name } }
          ]
        )
      ).to eq("customer_name_cont" => "山田")
    end

    it "converts equality and comparison filters" do
      expect(
        described_class.filter_params(
          status: { operator: :equals, value: "出荷済" },
          amount: { operator: :gteq, value: 1000 },
          delivery_date: { operator: :lteq, value: "2026-01-31" }
        )
      ).to eq(
        "status_eq" => "出荷済",
        "amount_gteq" => 1000,
        "delivery_date_lteq" => "2026-01-31"
      )
    end

    it "converts between filters to lower and upper predicates" do
      expect(
        described_class.filter_params(
          delivery_date: { operator: :between, from: "2026-01-01", to: "2026-01-31" }
        )
      ).to eq(
        "delivery_date_gteq" => "2026-01-01",
        "delivery_date_lteq" => "2026-01-31"
      )
    end

    it "keeps only present between bounds" do
      expect(
        described_class.filter_params(
          delivery_date: { operator: :between, from: "2026-01-01", to: "" },
          amount: { operator: :between, from: nil, to: 5000 }
        )
      ).to eq(
        "delivery_date_gteq" => "2026-01-01",
        "amount_lteq" => 5000
      )
    end

    it "uses column filter param metadata for between filters" do
      expect(
        described_class.filter_params(
          { customer_id: { operator: :between, from: 10, to: 20 } },
          columns: [
            { key: :customer_id, filter: { param: :orders_count } }
          ]
        )
      ).to eq(
        "orders_count_gteq" => 10,
        "orders_count_lteq" => 20
      )
    end

    it "converts inclusion filters" do
      expect(
        described_class.filter_params(
          status: { operator: :in, values: %w[未出荷 出荷済] }
        )
      ).to eq("status_in" => %w[未出荷 出荷済])
    end

    it "drops blank inclusion values while preserving false and zero" do
      expect(
        described_class.filter_params(
          status: { operator: :in, values: ["未出荷", "", nil, false, 0, "出荷済"] },
          archived: { operator: :not_in, values: ["", nil] },
          code: { operator: :in, value: 0 }
        )
      ).to eq(
        "status_in" => ["未出荷", false, 0, "出荷済"],
        "code_in" => [0]
      )
    end

    it "converts blank and present filters without requiring a user value" do
      expect(
        described_class.filter_params(
          memo: { operator: :blank },
          customer_code: { operator: :present }
        )
      ).to eq(
        "memo_blank" => true,
        "customer_code_present" => true
      )
    end

    it "converts true and false filters without requiring a user value" do
      expect(
        described_class.filter_params(
          active: { operator: :true },
          archived: { operator: :false, value: "" }
        )
      ).to eq(
        "active_true" => true,
        "archived_false" => true
      )
    end

    it "skips empty values for value-based predicates" do
      expect(
        described_class.filter_params(
          customer_name: { operator: :contains, value: "" },
          status: { operator: :equals, value: nil },
          memo: { operator: :blank }
        )
      ).to eq("memo_blank" => true)
    end

    it "ignores unsupported operators" do
      expect(
        described_class.filter_params(
          customer_name: { operator: :unsupported, value: "山田" }
        )
      ).to eq({})
    end
  end

  describe ".sort_params" do
    it "converts normalized sorts to Ransack sort values" do
      expect(
        described_class.sort_params(
          [
            { key: :delivery_date, direction: :desc },
            { key: :customer_code, direction: :asc }
          ]
        )
      ).to eq("s" => ["delivery_date desc", "customer_code asc"])
    end

    it "uses column sort param metadata when provided" do
      expect(
        described_class.sort_params(
          [{ key: :customer_id, direction: :asc }],
          columns: [
            { key: :customer_id, sort_param: :customer_name }
          ]
        )
      ).to eq("s" => ["customer_name asc"])
    end

    it "ignores invalid sort directions" do
      expect(
        described_class.sort_params(
          [
            { key: :delivery_date, direction: :sideways },
            { key: :customer_code, direction: :asc }
          ]
        )
      ).to eq("s" => ["customer_code asc"])
    end
  end

  describe ".to_params" do
    it "combines filter and sort params" do
      expect(
        described_class.to_params(
          filters: {
            customer_name: { operator: :contains, value: "山田" },
            status: { operator: :in, values: %w[未出荷 出荷済] }
          },
          sorts: [
            { key: :delivery_date, direction: :desc }
          ]
        )
      ).to eq(
        "customer_name_cont" => "山田",
        "status_in" => %w[未出荷 出荷済],
        "s" => ["delivery_date desc"]
      )
    end

    it "combines between filter params with sorts" do
      expect(
        described_class.to_params(
          filters: {
            delivery_date: { operator: :between, from: "2026-01-01", to: "2026-01-31" }
          },
          sorts: [
            { key: :delivery_date, direction: :desc }
          ]
        )
      ).to eq(
        "delivery_date_gteq" => "2026-01-01",
        "delivery_date_lteq" => "2026-01-31",
        "s" => ["delivery_date desc"]
      )
    end

    it "uses column metadata while preserving fallback keys" do
      expect(
        described_class.to_params(
          filters: {
            customer_id: { operator: :contains, value: "山田" },
            status: { operator: :equals, value: "出荷済" }
          },
          sorts: [
            { key: :customer_id, direction: :asc },
            { key: :created_at, direction: :desc }
          ],
          columns: [
            { key: :customer_id, filter: { param: :customer_name }, sort_param: :customer_name },
            { key: :status, filter: { type: :select } },
            { key: :created_at }
          ]
        )
      ).to eq(
        "customer_name_cont" => "山田",
        "status_eq" => "出荷済",
        "s" => ["customer_name asc", "created_at desc"]
      )
    end
  end
end
