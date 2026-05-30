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

    it "converts inclusion filters" do
      expect(
        described_class.filter_params(
          status: { operator: :in, values: %w[未出荷 出荷済] }
        )
      ).to eq("status_in" => %w[未出荷 出荷済])
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
